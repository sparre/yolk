-------------------------------------------------------------------------------
--                                                                           --
--                   Copyright (C) 2010-, Thomas Løcke                   --
--                                                                           --
--  This library is free software;  you can redistribute it and/or modify    --
--  it under terms of the  GNU General Public License  as published by the   --
--  Free Software  Foundation;  either version 3,  or (at your  option) any  --
--  later version. This library is distributed in the hope that it will be   --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of  --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     --
--                                                                           --
--  As a special exception under Section 7 of GPL version 3, you are         --
--  granted additional permissions described in the GCC Runtime Library      --
--  Exception, version 3.1, as published by the Free Software Foundation.    --
--                                                                           --
--  You should have received a copy of the GNU General Public License and    --
--  a copy of the GCC Runtime Library Exception along with this program;     --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
--  <http://www.gnu.org/licenses/>.                                          --
--                                                                           --
-------------------------------------------------------------------------------

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with GNATCOLL.Email;

package Yolk.Email is

   Attachment_File_Not_Found        : exception;
   --  Is raised if a file attachment is not found.
   No_Address_Set                   : exception;
   --  Is raised if the address component is missing in an Email_Data record.
   No_Sender_Set_With_Multiple_From : exception;
   --  Is raised when an email contains multiple From headers but no Sender
   --  header, as per RFC-5322, 3.6.2. http://tools.ietf.org/html/rfc5322
   No_SMTP_Host_Set                 : exception;
   --  Is raised if the SMTP host list is empty.

   type Character_Set is (US_ASCII,
                          ISO_8859_1,
                          ISO_8859_2,
                          ISO_8859_3,
                          ISO_8859_4,
                          ISO_8859_9,
                          ISO_8859_10,
                          ISO_8859_13,
                          ISO_8859_14,
                          ISO_8859_15,
                          Windows_1252,
                          UTF8);
   --  The available character sets. We try to provide the same character sets
   --  as defined in gnatcoll-email.ads.

   type Recipient_Kind is (Bcc, Cc, To);
   --  The kind of recipient, when adding a new recipient to an email.

   type Structure is private;
   --  The email structure. This type holds all the information needed to build
   --  a proper email.

private

   use Ada.Containers;
   use Ada.Strings.Unbounded;

   function U
     (S : in String)
      return Unbounded_String
      renames To_Unbounded_String;

   type Attachment_Data is
      record
         Charset      : Character_Set := US_ASCII;
         Path_To_File : Unbounded_String;
      end record;

   type Email_Data is
      record
         Address : Unbounded_String;
         Charset : Character_Set  := US_ASCII;
         Name    : Unbounded_String;
      end record;

   type Email_Kind is (Text,
                       Text_With_Attachment,
                       Text_And_HTML,
                       Text_And_HTML_With_Attachment);

   type Header_Data is
      record
         Charset : Character_Set := US_ASCII;
         Name    : Unbounded_String;
         Value   : Unbounded_String;
      end record;

   type SMTP_Server is
      record
         Host : Unbounded_String;
         Port : Positive;
      end record;

   type Subject_Data is
      record
         Content : Unbounded_String;
         Charset : Character_Set := US_ASCII;
      end record;

   type Text_Data is
      record
         Content : Unbounded_String;
         Charset : Character_Set := US_ASCII;
      end record;
   --  This type is used for both text and HTML parts, so the "Text" part of
   --  Text_Data simply refers to the fact that both text and HTML parts are
   --  essentially plain text data.

   package Attachments_Container is new Vectors (Positive, Attachment_Data);
   package Custom_Headers_Container is new Vectors (Positive, Header_Data);
   package Email_Data_Container is new Vectors (Positive, Email_Data);
   package SMTP_Servers_Container is new Vectors (Positive, SMTP_Server);

   type Structure is
      record
         Attachment_List  : Attachments_Container.Vector;
         Bcc_List         : Email_Data_Container.Vector;
         Cc_List          : Email_Data_Container.Vector;
         Composed_Message : GNATCOLL.Email.Message;
         Custom_Headers   : Custom_Headers_Container.Vector;
         Email_Is_Sent    : Boolean := False;
         From_List        : Email_Data_Container.Vector;
         Has_Attachment   : Boolean := False;
         Has_HTML_Part    : Boolean := False;
         Has_Text_Part    : Boolean := False;
         HTML_Part        : Text_Data;
         Reply_To_List    : Email_Data_Container.Vector;
         Sender           : Email_Data;
         SMTP_List        : SMTP_Servers_Container.Vector;
         Subject          : Subject_Data;
         Text_Part        : Text_Data;
         To_List          : Email_Data_Container.Vector;
         Type_Of_Email    : Email_Kind;
      end record;
   --  The type used to hold describe an email.
   --    Attachment_List:
   --       A list of Attachment_Data records. The validity of the Path_To_File
   --       component is checked when it is converted into a GNATcoll Virtual
   --       file.
   --    Bcc_List:
   --       A list of Email_Data records. These are collapsed into a single
   --       Bcc: header when Send is called, and only then do we check if each
   --       element is valid.
   --    Cc_List:
   --       A list of Email_Data records. These are collapsed into a single Cc:
   --       header when Send is called, and only then do we check if each
   --       element is valid.
   --    Composed_Message:
   --       The complete email in GNATCOLL.Email.Message format.
   --    Custom_Headers:
   --       A list of custom headers.
   --    Email_Is_Send:
   --       Is set to True if we succeed in sending the email.
   --    From_List:
   --       A list of Email_Data records. These are collapsed into a single
   --       From: header when Send is called, and only then do we check if each
   --       element is valid.
   --    Has_Attachment:
   --       Is set to True if an attachment is added to the email.
   --    Has_HTML_Part:
   --       Is set to True if a HTML part is added to the email.
   --    Has_Text_Part:
   --       Is set to True if a Text part is added to the email.
   --    HTML_Part:
   --       The HTML part of a multipart/alternative email.
   --    Reply_To_List:
   --       List of Email_Data records. These are collapsed into a single
   --       Reply-To: header when Send is called, and only then do we check if
   --       each element is valid.
   --    Sender:
   --       If From_List contains multiple elements, then a Sender: header is
   --       required as per RFC 5322 3.6.2. This header is build from the value
   --       of Sender.
   --    SMTP_List:
   --       List of SMTP servers to try when sending the email. The first one
   --       added to the list, is the first one tried. The system will keep
   --       going down the list, until it either succeeds in sending the email
   --       or until it runs out of SMTP servers to try.
   --    Status:
   --       The status code and message from the SMTP session.
   --    Subject:
   --       From this we build the Subject: header.
   --    Text_Part:
   --       The text/plain part of an email.
   --    To_List:
   --       List of Email_Data records. These are collapsed into a single To:
   --       header when send is called, and only then do we check if each
   --       element is valid.
   --    Type_Of_Email:
   --       The kind of email we're dealing with.

   procedure Generate_Text_And_HTML_Email
     (ES : in out Structure);
   --  Generate a text and HTML email using the GNATcoll email facilities.

   procedure Generate_Text_With_Attachment_Email
     (ES : in out Structure);
   --  Generate a text email with attachment(s) using the GNATcoll email
   --  facilities.

   procedure Generate_Text_Email
     (ES : in out Structure);
   --  Generate a text email using the GNATcoll email facilities.

   procedure Generate_Text_And_HTML_With_Attachment_Email
     (ES : in out Structure);
   --  Generate a text and HTML email with attachment(s) using the GNATcoll
   --  email facilities.

   function Get_Charset
     (Charset : in Character_Set)
      return String;
   --  Return the GNATcoll.Email character set string constant that is
   --  equivalent to the given Email.Character_Set enum.

   procedure Set_Type_Of_Email
     (ES : in out Structure);
   --  Figure out the kind of email ES is.

end Yolk.Email;

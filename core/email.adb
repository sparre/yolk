-------------------------------------------------------------------------------
--                                                                           --
--                                  Yolk                                     --
--                                                                           --
--                                  email                                    --
--                                                                           --
--                                  BODY                                     --
--                                                                           --
--                   Copyright (C) 2010-2011, Thomas L�cke                   --
--                                                                           --
--  Yolk is free software;  you can  redistribute it  and/or modify it under --
--  terms of the  GNU General Public License as published  by the Free Soft- --
--  ware  Foundation;  either version 2,  or (at your option) any later ver- --
--  sion.  Yolk is distributed in the hope that it will be useful, but WITH- --
--  OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
--  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
--  for  more details.  You should have  received  a copy of the GNU General --
--  Public License  distributed with Yolk.  If not, write  to  the  Free     --
--  Software Foundation,  51  Franklin  Street,  Fifth  Floor, Boston,       --
--  MA 02110 - 1301, USA.                                                    --
--                                                                           --
-------------------------------------------------------------------------------

with Ada.Calendar;
with Ada.Directories;
with Ada.Text_IO;
with AWS.MIME;
with AWS.Utils;
with GNATCOLL.Email;
with GNATCOLL.Email.Utils;
with GNATCOLL.VFS;
with Utilities;
--  with AWS.Headers;
--  with AWS.MIME;
--  with AWS.Utils;
--  with AWS.SMTP.Client;
--  with Utilities;         use Utilities;

package body Email is

   procedure Build_Attachments
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Add attachments to Email.

   procedure Build_Bcc_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the Bcc header and add it to Email.

   procedure Build_Cc_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the Cc header and add it to Email.

   procedure Build_Content_Transfer_Encoding_Header
     (ES    : in Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the Content-Transfer-Encoding header and add it to Email.

   procedure Build_Content_Type_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message;
      Kind  : in String);
   --  Build the Content-Type header and add it to Email.

   procedure Build_Date_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the Date header and add it to Email.

   procedure Build_Email_Data
     (Header   : in out GNATCOLL.Email.Header;
      List     : in     Email_Data_Container.Vector);
   --  Construct the actual content for the sender/recipient headers, such as
   --  To, Cc, Bcc, Reply-To and so on.

   procedure Build_From_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the From header and add it to Email.

   procedure Build_MIME_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the MIME-Version header and add it to Email.

   procedure Build_Reply_To_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the Reply-To header and add it to Email.

   procedure Build_Sender_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the Sender header and add it to Email.

   procedure Build_Subject_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the Subject header and add it to Email.

   procedure Build_To_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message);
   --  Build the To header and add it to Email.

   function Generate_Text_And_HTML_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String;
   --  Generate a text and HTML email using the GNATcoll email facilities.

   function Generate_Text_With_Attachment_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String;
   --  Generate a text email with attachment(s) using the GNATcoll email
   --  facilities.

   function Generate_Text_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String;
   --  Generate a text email using the GNATcoll email facilities.

   function Generate_Text_And_HTML_With_Attachment_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String;
   --  Generate a text and HTML email with attachment(s) using the GNATcoll
   --  email facilities.

   function Get_Charset
     (Charset : in Character_Set)
      return String;
   --  Return the GNATcoll.Email character set string constant that is
   --  equivalent to the given Email.Character_Set enum.

   procedure Set_Type_Of_Email
     (ES : in out Email_Structure);
   --  Figure out the kind of email ES is.

   function To_Virtual_File
     (Item : in Attachment_Data)
      return GNATCOLL.VFS.Virtual_File;
   --  Convert an Attachment_Data.Path_To_File to a GNATCOLL.VFS Virtual_File.
   --  Exceptions:
   --    Attachment_File_Not_Found

   ---------------------------
   --  Add_File_Attachment  --
   ---------------------------

   procedure Add_File_Attachment
     (ES            : in out Email_Structure;
      Path_To_File  : in     String;
      Charset       : in     Character_Set := US_ASCII)
   is

      use Utilities;

      New_Attachment : Attachment_Data;

   begin

      New_Attachment.Charset        := Charset;
      New_Attachment.Path_To_File   := TUS (Path_To_File);
      ES.Attachment_List.Append (New_Attachment);

      ES.Has_Attachment := True;

   end Add_File_Attachment;

   ----------------
   --  Add_From  --
   ----------------

   procedure Add_From
     (ES        : in out Email_Structure;
      Address   : in     String;
      Name      : in     String := "";
      Charset   : in     Character_Set := US_ASCII)
   is

      use Utilities;

      New_From : Email_Data;

   begin

      New_From.Address  := TUS (Address);
      New_From.Charset  := Charset;
      New_From.Name     := TUS (Name);
      ES.From_List.Append (New_Item => New_From);

   end Add_From;

   ---------------------
   --  Add_Recipient  --
   ---------------------

   procedure Add_Recipient
     (ES       : in out Email_Structure;
      Address  : in     String;
      Name     : in     String := "";
      Kind     : in     Recipient_Kind := To;
      Charset  : in     Character_Set := US_ASCII)
   is

      use Utilities;

      New_Recipient : Email_Data;

   begin

      New_Recipient.Address   := TUS (Address);
      New_Recipient.Charset   := Charset;
      New_Recipient.Name      := TUS (Name);

      case Kind is
         when Bcc =>
            ES.Bcc_List.Append (New_Item => New_Recipient);
         when Cc =>
            ES.Cc_List.Append (New_Item => New_Recipient);
         when To =>
            ES.To_List.Append (New_Item => New_Recipient);
      end case;

   end Add_Recipient;

   --------------------
   --  Add_Reply_To  --
   --------------------

   procedure Add_Reply_To
     (ES       : in out Email_Structure;
      Address  : in     String;
      Name     : in     String := "";
      Charset  : in     Character_Set := US_ASCII)
   is

      use Utilities;

      New_Reply_To : Email_Data;

   begin

      New_Reply_To.Address := TUS (Address);
      New_Reply_To.Charset := Charset;
      New_Reply_To.Name    := TUS (Name);
      ES.Reply_To_List.Append (New_Item => New_Reply_To);

   end Add_Reply_To;

   -----------------------
   --  Add_SMTP_Server  --
   -----------------------

   procedure Add_SMTP_Server
     (ES    : in out Email_Structure;
      Host  : in     String;
      Port  : in     Positive := 25)
   is

      use Utilities;

      New_SMTP : SMTP_Server;

   begin

      New_SMTP.Host := TUS (Host);
      New_SMTP.Port := Port;
      ES.SMTP_List.Append (New_Item => New_SMTP);

   end Add_SMTP_Server;

   -------------------------
   --  Build_Attachments  --
   -------------------------

   procedure Build_Attachments
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is
   begin

      for i in
        ES.Attachment_List.First_Index .. ES.Attachment_List.Last_Index loop
         declare

            use GNATCOLL.VFS;
            use Utilities;

            Data : constant Attachment_Data := ES.Attachment_List.Element (i);
            File : constant Virtual_File := To_Virtual_File (Item => Data);

         begin

            Email.Attach
              (Path                 => File,
               MIME_Type            => AWS.MIME.Content_Type
                 (Filename => TS (Data.Path_To_File)),
               Charset              => Get_Charset (Data.Charset));

         end;
      end loop;

   end Build_Attachments;

   ------------------------
   --  Build_Bcc_Header  --
   ------------------------

   procedure Build_Bcc_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is
   begin

      if not ES.Bcc_List.Is_Empty then
         declare

            use GNATCOLL.Email;

            Bcc : Header := Create (Name  => "Bcc",
                                    Value => "");

         begin

            Build_Email_Data (Header => Bcc,
                              List   => ES.Bcc_List);

            Email.Add_Header (H => Bcc);

         end;
      end if;

   end Build_Bcc_Header;

   -----------------------
   --  Build_Cc_Header  --
   -----------------------

   procedure Build_Cc_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is
   begin

      if not ES.Cc_List.Is_Empty then
         declare

            use GNATCOLL.Email;

            Cc : Header := Create (Name   => "Cc",
                                   Value  => "");

         begin

            Build_Email_Data (Header => Cc,
                              List   => ES.Cc_List);

            Email.Add_Header (H => Cc);

         end;
      end if;

   end Build_Cc_Header;

   ----------------------------------------------
   --  Build_Content_Transfer_Encoding_Header  --
   ----------------------------------------------

   procedure Build_Content_Transfer_Encoding_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is

      use GNATCOLL.Email;

      CTE : constant Header := Create (Name  => Content_Transfer_Encoding,
                                       Value => "8bit");

   begin

      Email.Add_Header (H => CTE);

   end Build_Content_Transfer_Encoding_Header;

   ---------------------------------
   --  Build_Content_Type_Header  --
   ---------------------------------

   procedure Build_Content_Type_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message;
      Kind  : in     String)
   is

      use GNATCOLL.Email;

      CT : Header;

   begin

      CT := Create (Name   => Content_Type,
                    Value  => Kind);
      CT.Set_Param (Param_Name  => "charset",
                    Param_Value => Get_Charset (ES.Text_Part.Charset));
      Email.Add_Header (H => CT);

   end Build_Content_Type_Header;

   -------------------------
   --  Build_Date_Header  --
   -------------------------

   procedure Build_Date_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is

      use GNATCOLL.Email;
      use GNATCOLL.Email.Utils;

      Date : constant Header := Create
        (Name  => "Date",
         Value => Format_Date (Date => Ada.Calendar.Clock));

   begin

      Email.Add_Header (H => Date);

   end Build_Date_Header;

   ------------------------
   --  Build_Email_Data  --
   ------------------------

   procedure Build_Email_Data
     (Header   : in out GNATCOLL.Email.Header;
      List     : in     Email_Data_Container.Vector)
   is

      use Utilities;

      Data : Email_Data;

   begin

      for i in List.First_Index .. List.Last_Index loop
         Data := List.Element (i);

         if Is_Empty (Data.Address) then
            raise No_Address_Set;
         end if;

         if Data.Name = "" then
            Header.Append (Value   => TS (Data.Address));
         else
            Header.Append (Value   => TS (Data.Name),
                           Charset => Get_Charset (Data.Charset));
            Header.Append (Value => " <" & TS (Data.Address) & ">");
         end if;

         if i /= List.Last_Index then
            Header.Append (Value => ", ");
         end if;
      end loop;

   end Build_Email_Data;

   -------------------------
   --  Build_From_Header  --
   -------------------------

   procedure Build_From_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is

      use GNATCOLL.Email;

      From : Header := Create (Name    => "From",
                               Value   => "");

   begin

      Build_Email_Data (Header => From,
                        List   => ES.From_List);

      Email.Add_Header (H => From);

   end Build_From_Header;

   -------------------------
   --  Build_MIME_Header  --
   -------------------------

   procedure Build_MIME_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is

      use GNATCOLL.Email;

      MIME : constant Header := Create (Name  => MIME_Version,
                                        Value => "1.0");

   begin

      Email.Add_Header (H => MIME);

   end Build_MIME_Header;

   -----------------------------
   --  Build_Reply_To_Header  --
   -----------------------------

   procedure Build_Reply_To_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is
   begin

      if not ES.Reply_To_List.Is_Empty then
         declare

            use GNATCOLL.Email;

            Reply_To : Header := Create (Name   => "Reply-To",
                                         Value  => "");

         begin

            Build_Email_Data (Header => Reply_To,
                              List   => ES.Reply_To_List);

            Email.Add_Header (H => Reply_To);

         end;
      end if;

   end Build_Reply_To_Header;

   ---------------------------
   --  Build_Sender_Header  --
   ---------------------------

   procedure Build_Sender_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is
   begin

      if ES.Sender.Address /= Null_Unbounded_String then
         declare

            use GNATCOLL.Email;
            use Utilities;

            Sender : Header;

         begin

            if ES.Sender.Name = "" then
               Sender := Create (Name    => "Sender",
                                 Value   => TS (ES.Sender.Address),
                                 Charset => Get_Charset (ES.Sender.Charset));
            else
               Sender := Create (Name    => "Sender",
                                 Value   => TS (ES.Sender.Name),
                                 Charset => Get_Charset (ES.Sender.Charset));
               Sender.Append
                 (Value   => " <" & TS (ES.Sender.Address) & ">");
            end if;

            Email.Add_Header (H => Sender);

         end;
      else
         if ES.From_List.Length > 1 then
            raise No_Sender_Set_With_Multiple_From;
         end if;
      end if;

   end Build_Sender_Header;

   ----------------------------
   --  Build_Subject_Header  --
   ----------------------------

   procedure Build_Subject_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is

      use GNATCOLL.Email;
      use Utilities;

      Subject  : constant Header := Create
        (Name    => "Subject",
         Value   => TS (ES.Subject.Content),
         Charset => Get_Charset (ES.Subject.Charset));

   begin

      Email.Add_Header (H => Subject);

   end Build_Subject_Header;

   -------------------------
   --  Build_To_Header  --
   -------------------------

   procedure Build_To_Header
     (ES    : in     Email_Structure;
      Email : in out GNATCOLL.Email.Message)
   is

      use GNATCOLL.Email;

      To : Header := Create (Name   => "To",
                             Value  => "");

   begin

      Build_Email_Data (Header => To,
                        List   => ES.To_List);

      Email.Add_Header (H => To);

   end Build_To_Header;

   ------------------------------------
   --  Generate_Text_And_HTML_Email  --
   ------------------------------------

   function Generate_Text_And_HTML_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String
   is

      use GNATCOLL.Email;
      use Utilities;

      Email          : Message := New_Message (MIME_Type => Multipart_Mixed);
      HTML_Payload   : Message := New_Message (MIME_Type => Text_Html);
      Text_Payload   : Message := New_Message (MIME_Type => Text_Plain);
      US             : Unbounded_String := Null_Unbounded_String;

   begin

      --  Set multipart boundaries for Email.
      Email.Set_Boundary (Boundary => AWS.Utils.Random_String (16));

      --  set the text payload and then we clear all the pre-made headers.
      Text_Payload.Set_Text_Payload
        (Payload   => TS (ES.Text_Part.Content),
         Charset   => Get_Charset (ES.Text_Part.Charset));

      Text_Payload.Delete_Headers (Name => "");

      --  Add the Content-Transfer-Encoding header to the text payload.
      Build_Content_Transfer_Encoding_Header (ES    => ES,
                                              Email => Text_Payload);

      --  Add the Content-Type header to the text payload.
      Build_Content_Type_Header (ES    => ES,
                                 Email => Text_Payload,
                                 Kind  => Text_Plain);

      --  set the HTML payload and then we clear all the pre-made headers.
      HTML_Payload.Set_Text_Payload
        (Payload   => TS (ES.HTML_Part.Content),
         Charset   => Get_Charset (ES.HTML_Part.Charset));

      HTML_Payload.Delete_Headers (Name => "");

      --  Add the Content-Transfer-Encoding header to the HTML payload.
      Build_Content_Transfer_Encoding_Header (ES    => ES,
                                              Email => HTML_Payload);

      --  Add the Content-Type header to the HTML payload.
      Build_Content_Type_Header (ES    => ES,
                                 Email => HTML_Payload,
                                 Kind  => Text_Html);

      --  Add the text payload to Email.
      Email.Add_Payload (Payload => Text_Payload,
                         First   => True);

      --  Add the HTML payload to Email.
      Email.Add_Payload (Payload => HTML_Payload,
                         First   => False);

      --  Add the MIME preamble.
      Email.Set_Preamble
        (Preamble => "This is a multi-part message in MIME format.");

      --  Finally we output the raw email.
      Email.To_String (Result => US);

      return US;

   end Generate_Text_And_HTML_Email;

   ----------------------------------------------------
   --  Generate_Text_And_HTML_With_Attachment_Email  --
   ----------------------------------------------------

   function Generate_Text_And_HTML_With_Attachment_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String
   is

      pragma Unreferenced (ES);
      use Utilities;

   begin

      return TUS ("Text and HTML with attachment type");

   end Generate_Text_And_HTML_With_Attachment_Email;

   ---------------------------
   --  Generate_Text_Email  --
   ---------------------------

   function Generate_Text_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String
   is

      use GNATCOLL.Email;
      use Utilities;

      Email : Message := New_Message (MIME_Type => Text_Plain);
      US    : Unbounded_String := Null_Unbounded_String;

   begin

      --  First we set the text payload and then we clear all the pre-made
      --  headers.
      Email.Set_Text_Payload
        (Payload   => TS (ES.Text_Part.Content),
         Charset   => Get_Charset (ES.Text_Part.Charset));

      Email.Delete_Headers (Name => "");

      --  Add the Bcc header
      Build_Bcc_Header (ES    => ES,
                        Email => Email);

      --  Add the Cc header
      Build_Cc_Header (ES    => ES,
                       Email => Email);

      --  Add the Content-Transfer-Encoding header
      Build_Content_Transfer_Encoding_Header (ES    => ES,
                                              Email => Email);

      --  Add the Content-Type header
      Build_Content_Type_Header (ES    => ES,
                                 Email => Email,
                                 Kind  => Text_Plain);

      --  Add the Date header
      Build_Date_Header (ES    => ES,
                         Email => Email);

      --  Add the From header
      Build_From_Header (ES    => ES,
                         Email => Email);

      --  Add the MIME-Version header.
      Build_MIME_Header (ES    => ES,
                         Email => Email);

      --  Add the Reply-To header
      Build_Reply_To_Header (ES    => ES,
                             Email => Email);

      --  Add the Sender header
      Build_Sender_Header (ES    => ES,
                           Email => Email);

      --  Add the Subject header
      Build_Subject_Header (ES    => ES,
                            Email => Email);

      --  Add the To header
      Build_To_Header (ES    => ES,
                       Email => Email);

      --  Finally we output the raw email.
      Email.To_String (Result => US);

      return US;

   end Generate_Text_Email;

   -------------------------------------------
   --  Generate_Text_With_Attachment_Email  --
   -------------------------------------------

   function Generate_Text_With_Attachment_Email
     (ES : in Email_Structure)
      return Ada.Strings.Unbounded.Unbounded_String
   is

      use GNATCOLL.Email;
      use Utilities;

      Email          : Message := New_Message (MIME_Type => Multipart_Mixed);
      Text_Payload   : Message := New_Message (MIME_Type => Text_Plain);
      US             : Unbounded_String := Null_Unbounded_String;

   begin

      --  Set multipart boundaries for Email.
      Email.Set_Boundary (Boundary => AWS.Utils.Random_String (16));

      --  set the text payload and then we clear all the pre-made headers.
      Text_Payload.Set_Text_Payload
        (Payload   => TS (ES.Text_Part.Content),
         Charset   => Get_Charset (ES.Text_Part.Charset));

      Text_Payload.Delete_Headers (Name => "");

      --  Add the Content-Transfer-Encoding header to the text payload.
      Build_Content_Transfer_Encoding_Header (ES    => ES,
                                              Email => Text_Payload);

      --  Add the Content-Type header to the text payload.
      Build_Content_Type_Header (ES    => ES,
                                 Email => Text_Payload,
                                 Kind  => Text_Plain);

      --  Add the text payload to Email.
      Email.Add_Payload (Payload => Text_Payload,
                         First   => True);

      --  Add attachments to Email.
      Build_Attachments (ES    => ES,
                         Email => Email);

      --  Add the MIME preamble.
      Email.Set_Preamble
        (Preamble => "This is a multi-part message in MIME format.");

      --  Add the Bcc header to Email.
      Build_Bcc_Header (ES    => ES,
                        Email => Email);

      --  Add the Cc header to Email.
      Build_Cc_Header (ES    => ES,
                       Email => Email);

      --  Add the Date header to Email.
      Build_Date_Header (ES    => ES,
                         Email => Email);

      --  Add the From header
      Build_From_Header (ES    => ES,
                         Email => Email);

      --  Add the MIME-Version header.
      Build_MIME_Header (ES    => ES,
                         Email => Email);

      --  Add the Reply-To header
      Build_Reply_To_Header (ES    => ES,
                             Email => Email);

      --  Add the Sender header
      Build_Sender_Header (ES    => ES,
                           Email => Email);

      --  Add the Subject header
      Build_Subject_Header (ES    => ES,
                            Email => Email);

      --  Add the To header
      Build_To_Header (ES    => ES,
                       Email => Email);

      --  Finally we output the raw email.
      Email.To_String (Result => US);

      return US;

   end Generate_Text_With_Attachment_Email;

   -------------------
   --  Get_Charset  --
   -------------------

   function Get_Charset
     (Charset : in Character_Set)
      return String
   is
   begin

      case Charset is
         when US_ASCII => return GNATCOLL.Email.Charset_US_ASCII;
         when ISO_8859_1 => return GNATCOLL.Email.Charset_ISO_8859_1;
         when ISO_8859_2 => return GNATCOLL.Email.Charset_ISO_8859_2;
         when ISO_8859_3 => return GNATCOLL.Email.Charset_ISO_8859_3;
         when ISO_8859_4 => return GNATCOLL.Email.Charset_ISO_8859_4;
         when ISO_8859_9 => return GNATCOLL.Email.Charset_ISO_8859_9;
         when ISO_8859_10 => return GNATCOLL.Email.Charset_ISO_8859_10;
         when ISO_8859_13 => return GNATCOLL.Email.Charset_ISO_8859_13;
         when ISO_8859_14 => return GNATCOLL.Email.Charset_ISO_8859_14;
         when ISO_8859_15 => return GNATCOLL.Email.Charset_ISO_8859_15;
         when Windows_1252 => return GNATCOLL.Email.Charset_Windows_1252;
         when UTF8 => return "utf-8";
      end case;

   end Get_Charset;

   ---------------
   --  Is_Send  --
   ---------------

   function Is_Send
     (ES : in Email_Structure)
      return Boolean
   is
   begin

      return ES.Email_Is_Send;

   end Is_Send;

   ------------
   --  Send  --
   ------------

   procedure Send
     (ES : in out Email_Structure)
   is

      use Ada.Text_IO;
      use Utilities;

      Email_String : Unbounded_String := Null_Unbounded_String;

   begin

      Set_Type_Of_Email (ES => ES);

      case ES.Type_Of_Email is
         when Text =>
            Email_String := Generate_Text_Email (ES);
         when Text_With_Attachment =>
            Email_String := Generate_Text_With_Attachment_Email (ES);
         when Text_And_HTML =>
            Email_String := Generate_Text_And_HTML_Email (ES);
         when Text_And_HTML_With_Attachment =>
            Email_String := Generate_Text_And_HTML_With_Attachment_Email (ES);
      end case;

      Put_Line (TS (Email_String));

   end Send;

   ------------
   --  Send  --
   ------------

   procedure Send
     (ES             : in out Email_Structure;
      From_Address   : in     String;
      From_Name      : in     String := "";
      To_Address     : in     String;
      To_Name        : in     String := "";
      Subject        : in     String;
      Text_Part      : in     String;
      SMTP_Server    : in     String;
      SMTP_Port      : in     Positive := 25;
      Charset        : in     Character_Set := US_ASCII)
   is
   begin

      Add_From (ES      => ES,
                Address => From_Address,
                Name    => From_Name,
                Charset => Charset);

      Add_Recipient (ES      => ES,
                     Address => To_Address,
                     Name    => To_Name,
                     Kind    => To,
                     Charset => Charset);

      Set_Subject (ES      => ES,
                   Subject => Subject,
                   Charset => Charset);

      Set_Text_Part (ES      => ES,
                     Part    => Text_Part,
                     Charset => Charset);

      Add_SMTP_Server (ES   => ES,
                       Host => SMTP_Server,
                       Port => SMTP_Port);

      Send (ES => ES);

   end Send;

   ------------
   --  Send  --
   ------------

   procedure Send
     (ES             : in out Email_Structure;
      From_Address   : in     String;
      From_Name      : in     String := "";
      To_Address     : in     String;
      To_Name        : in     String := "";
      Subject        : in     String;
      Text_Part      : in     String;
      HTML_Part      : in     String;
      SMTP_Server    : in     String;
      SMTP_Port      : in     Positive := 25;
      Charset        : in     Character_Set := US_ASCII)
   is
   begin

      Add_From (ES      => ES,
                Address => From_Address,
                Name    => From_Name,
                Charset => Charset);

      Add_Recipient (ES      => ES,
                     Address => To_Address,
                     Name    => To_Name,
                     Kind    => To,
                     Charset => Charset);

      Set_Subject (ES      => ES,
                   Subject => Subject,
                   Charset => Charset);

      Set_Text_Part (ES      => ES,
                     Part    => Text_Part,
                     Charset => Charset);

      Set_HTML_Part (ES      => ES,
                     Part    => HTML_Part,
                     Charset => Charset);

      Add_SMTP_Server (ES   => ES,
                       Host => SMTP_Server,
                       Port => SMTP_Port);

      Send (ES => ES);

   end Send;

   ---------------------
   --  Set_HTML_Part  --
   ---------------------

   procedure Set_HTML_Part
     (ES         : in out Email_Structure;
      Part       : in     String;
      Charset    : in     Character_Set := US_ASCII)
   is

      use Utilities;

   begin

      ES.HTML_Part.Content := TUS (Part);
      ES.HTML_Part.Charset := Charset;

      ES.Has_HTML_Part := True;

   end Set_HTML_Part;

   ------------------
   --  Set_Sender  --
   ------------------

   procedure Set_Sender
     (ES         : in out Email_Structure;
      Address    : in     String;
      Name       : in     String := "";
      Charset    : in     Character_Set := US_ASCII)
   is

      use Utilities;

   begin

      ES.Sender.Address := TUS (Address);
      ES.Sender.Charset := Charset;
      ES.Sender.Name    := TUS (Name);

   end Set_Sender;

   -------------------
   --  Set_Subject  --
   -------------------

   procedure Set_Subject
     (ES        : in out Email_Structure;
      Subject   : in     String;
      Charset   : in     Character_Set := US_ASCII)
   is

      use Utilities;

   begin

      ES.Subject.Content := TUS (Subject);
      ES.Subject.Charset := Charset;

   end Set_Subject;

   ---------------------
   --  Set_Text_Part  --
   ---------------------

   procedure Set_Text_Part
     (ES         : in out Email_Structure;
      Part       : in     String;
      Charset    : in     Character_Set := US_ASCII)
   is

      use Utilities;

   begin

      ES.Text_Part.Content := TUS (Part);
      ES.Text_Part.Charset := Charset;

      ES.Has_Text_Part := True;

   end Set_Text_Part;

   -------------------------
   --  Set_Type_Of_Email  --
   -------------------------

   procedure Set_Type_Of_Email
     (ES : in out Email_Structure)
   is
   begin

      if not ES.Has_Text_Part then
         Set_Text_Part (ES       => ES,
                        Part     => "");
      end if;
      ES.Type_Of_Email := Text;

      if ES.Has_HTML_Part then
         ES.Type_Of_Email := Text_And_HTML;
      end if;

      if ES.Has_Attachment then
         if ES.Type_Of_Email = Text then
            ES.Type_Of_Email := Text_With_Attachment;
         elsif ES.Type_Of_Email = Text_And_HTML then
            ES.Type_Of_Email := Text_And_HTML_With_Attachment;
         end if;
      end if;

   end Set_Type_Of_Email;

   -------------------
   --  Status_Code  --
   -------------------

   function Status_Code
     (ES : in Email_Structure)
      return Positive
   is
   begin

      return Positive (AWS.SMTP.Status_Code (Status => ES.Status));

   end Status_Code;

   ----------------------
   --  Status_Message  --
   ----------------------

   function Status_Message
     (ES : in Email_Structure)
      return String
   is
   begin

      return AWS.SMTP.Status_Message (Status => ES.Status);

   end Status_Message;

   -----------------------
   --  To_Virtual_File  --
   -----------------------

   function To_Virtual_File
     (Item : in Attachment_Data)
      return GNATCOLL.VFS.Virtual_File
   is

      use Ada.Directories;
      use GNATCOLL.VFS;
      use Utilities;

      Path_To_File : constant String := TS (Item.Path_To_File);

   begin

      if not Exists (Path_To_File) then
         raise Attachment_File_Not_Found;
      end if;

      return Locate_On_Path (Filesystem_String (Path_To_File));

   end To_Virtual_File;

   ------------------------------
   --  Send_Complex_Multipart  --
   ------------------------------

--     procedure Send_Complex_Multipart (ES : in out Email_Structure)
--     is
--
--        SMTP              : constant AWS.SMTP.Receiver
--          := AWS.SMTP.Client.Initialize (TS (ES.SMTP_List.Element (1)));
--        Email_Contents    : AWS.Attachments.List;
--        Status            : AWS.SMTP.Status;
--
--     begin
--
--        --  Add the alternative parts.
--        Set_Alternative_Parts (C   => Email_Contents,
--                               ES  => ES);
--
--        --  Add the file attachments.
--        Set_File_Attachments (C  => Email_Contents,
--                              ES => ES);
--
--        --  Send the email.
--        AWS.SMTP.Client.Send
--          (Server      => SMTP,
--           From        => ES.From,
--           To          => Get_Recipients (ES),
--           Subject     => To_String (ES.Subject),
--           Attachments => Email_Contents,
--           Status      => Status);
--
--        if AWS.SMTP.Is_Ok (Status) then
--           ES.Is_Email_Send := Yes;
--        end if;
--
--     end Send_Complex_Multipart;

   -----------------------------
   --  Send_Simple_Text_Only  --
   -----------------------------

--     procedure Send_Simple_Text_Only (ES : in out Email_Structure)
--     is
--
--        SMTP              : constant AWS.SMTP.Receiver
--          := AWS.SMTP.Client.Initialize (TS (ES.SMTP_List.Element (1)));
--        Status            : AWS.SMTP.Status;
--
--     begin
--
--        AWS.SMTP.Client.Send (Server  => SMTP,
--                              From    => ES.From,
--                              To      => Get_Recipients (ES),
--                              Subject => To_String (ES.Subject),
--                              Message => To_String (ES.Text_Part),
--                              Status  => Status);
--
--        if AWS.SMTP.Is_Ok (Status) then
--           ES.Is_Email_Send := Yes;
--        end if;
--
--     end Send_Simple_Text_Only;

   ------------------------
   --  Set_Alternatives  --
   ------------------------

--     procedure Set_Alternative_Parts (C  : in out AWS.Attachments.List;
--                                      ES : in     Email_Structure)
--     is
--
--        Alternative_Parts : AWS.Attachments.Alternatives;
--
--     begin
--
--        --  Alternative parts.
--        --  These are added with the least favorable part first and the most
--        --  favorable part last.
--        --  Alternative parts are simply just different versions of the same
--        --  content, usually a text and a HTML version.
--        --  If there a HTML part, then we favor that. Only when the HTML part
--        --  is empty do we favor the Text part.
--        if ES.HTML_Part = "" then
--           AWS.Attachments.Add
--             (Parts => Alternative_Parts,
--              Data  => AWS.Attachments.Value
--                (Data         => TS (ES.HTML_Part),
--                 Content_Type => AWS.MIME.Text_HTML &
--                 "; charset=" & TS (ES.Charset)));
--
--           AWS.Attachments.Add
--             (Parts => Alternative_Parts,
--              Data  => AWS.Attachments.Value
--                (Data         => TS (ES.Text_Part),
--                 Content_Type => AWS.MIME.Text_Plain &
--                 "; charset=" & TS (ES.Charset)));
--        else
--           AWS.Attachments.Add
--             (Parts => Alternative_Parts,
--              Data  => AWS.Attachments.Value
--                (Data         => TS (ES.Text_Part),
--                 Content_Type => AWS.MIME.Text_Plain &
--                 "; charset=" & TS (ES.Charset)));
--
--           AWS.Attachments.Add
--             (Parts => Alternative_Parts,
--              Data  => AWS.Attachments.Value
--                (Data         => TS (ES.HTML_Part),
--                 Content_Type => AWS.MIME.Text_HTML &
--                 "; charset=" & TS (ES.Charset)));
--        end if;
--
--        AWS.Attachments.Add (Attachments => C,
--                             Parts       => Alternative_Parts);
--
--     end Set_Alternative_Parts;

   ----------------------------
   --  Set_File_Attachments  --
   ----------------------------

--     procedure Set_File_Attachments (C   : in out AWS.Attachments.List;
--                                     ES  : in     Email_Structure)
--     is
--
--        ESA : File_Attachments.Vector renames ES.Attachments_List;
--
--     begin
--
--        for i in ESA.First_Index .. ESA.Last_Index loop
--           AWS.Attachments.Add
--             (Attachments => C,
--              Filename    => To_String (ESA.Element (i).File),
--              Headers     => AWS.Headers.Empty_List,
--              Name        => Simple_Name (To_String (ESA.Element (i).File)),
--              Encode      => ESA.Element (i).Encode);
--        end loop;
--  --        AWS.Attachments.Add (Attachments => C,
--  --                             Filename    => ES.Attachments_List,
--  --                             Headers     => AWS.Headers.Empty_List,
--  --                             Name        => "",
--  --                             Encode      => AWS.Attachments.Base64);
--  --
--  --        AWS.Attachments.Add (Attachments => C,
--  --                             Filename    => "test.lyx",
--  --                             Headers     => AWS.Headers.Empty_List,
--  --                             Name        => "",
--  --                             Encode      => AWS.Attachments.Base64);
--
--     end Set_File_Attachments;

end Email;

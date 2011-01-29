-------------------------------------------------------------------------------
--                                                                           --
--                                  Yolk                                     --
--                                                                           --
--                               view.index                                  --
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

with My_Configuration;
with Rotating_Log;
with Email;
--  with GNATCOLL.Email;
--  with GNATCOLL.Email.Utils;
with GNATCOLL.SQL;
with GNATCOLL.SQL.Exec;

--  with GNATCOLL.VFS; use GNATCOLL.VFS;

with Ada.Text_IO;
--  with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
--  with Ada.Calendar;

--  with AWS.MIME;
--  with AWS.Utils;

--  with AWS.SMTP.Client;

package body View.Index is

   ---------------
   --  Generate --
   ---------------

   function Generate
     (Request : in AWS.Status.Data)
      return AWS.Response.Data
   is

      use Ada.Text_IO;
      use AWS.Templates;
      use GNATCOLL;
      use Email;
      use Rotating_Log;

      package My renames My_Configuration;

      T : Translate_Set;

      DB1 : constant SQL.Exec.Database_Connection := View.DB_One.Connection;
      DB2 : constant SQL.Exec.Database_Connection := View.DB_Two.Connection;

      C1 : SQL.Exec.Forward_Cursor;
      C2 : SQL.Exec.Forward_Cursor;

   begin

      C1.Fetch (Connection => DB1,
                Query      => "select * from groups");
      while C1.Has_Row loop
         Put_Line (C1.Value (Field => 1));
         C1.Next;
      end loop;
      DB1.Commit_Or_Rollback;

      C2.Fetch (Connection => DB2,
                Query      => "select * from status");
      while C2.Has_Row loop
         Put_Line (C2.Value (Field => 1));
         C2.Next;
      end loop;
      DB2.Commit_Or_Rollback;

      Track (Handle     => Info,
             Log_String => "Testing the INFO track");

      Track (Handle     => Error,
             Log_String => "Testing the ERROR track");

      Insert (T, Assoc ("HANDLER", String'(My.Config.Get (My.Handler_Index))));
      Insert (T, Assoc ("TEMPLATE",
        String'(My.Config.Get (My.Template_Index))));
      Insert (T, Assoc ("URI", AWS.Status.URI (Request)));

      declare

         An_Email : Email_Structure;
         Bn_Email : Email_Structure;
         Cn_Email : Email_Structure;

      begin

         --  Manually build and send an email.
         Add_From (ES       => An_Email,
                   Address  => "thomas@responsum.dk",
                   Name     => "Thomas L�cke",
                   Charset  => UTF8);

         Add_Recipient (ES       => An_Email,
                        Address  => "thomas.granvej6@gmail.com",
                        Name     => "Thomas L�cke",
                        Charset  => UTF8);

         Add_File_Attachment (ES           => An_Email,
                              Path_To_File => "../../test.txt",
                              Charset      => UTF8);

         Add_SMTP_Server (ES     => An_Email,
                          Host   => My.Config.Get (My.SMTP));

         Set_Text_Part (ES       => An_Email,
                        Part     => "Text ��� ���",
                        Charset  => UTF8);

         Set_HTML_Part (ES       => An_Email,
                        Part     => "<b>HTML</b> ��� ���",
                        Charset  => UTF8);

         Send (ES => An_Email);

         --  Use a convenience procedure to build and send an email.
         Add_Recipient (ES      => Bn_Email,
                        Address => "tl@ada-dk.org",
                        Charset => ISO_8859_1);
         Add_Recipient (ES      => Bn_Email,
                        Name    => "CCThomas L�cke",
                        Address => "CCtl@ada-dk.org",
                        Kind    => Email.Cc,
                        Charset => ISO_8859_1);
         Add_Recipient (ES      => Bn_Email,
                        Name    => "BCCThomas L�cke",
                        Address => "BCCtl@ada-dk.org",
                        Kind    => Bcc,
                        Charset => ISO_8859_1);
         Send (ES             => Bn_Email,
               From_Address   => "thomas@responsum.dk",
               From_Name      => "Thomas L�cke",
               To_Address     => "thomas@12boo.net",
               To_Name        => "Thomas L�cke",
               Subject        => "Text Type Test ��� ���",
               Text_Part      => "Text Type Test ��� ���",
               SMTP_Server    => "freja.serverbox.dk",
               Charset        => ISO_8859_1);

         --  Use a convenience procedure to build and send an email.
         Send (ES             => Cn_Email,
               From_Address   => "thomas@responsum.dk",
               From_Name      => "Thomas L�cke",
               To_Address     => "thomas@12boo.net",
               To_Name        => "Thomas L�cke",
               Subject        => "Test ��� ���",
               Text_Part      => "Test ��� ���",
               HTML_Part      => "<b>Test</b> ��� ���",
               SMTP_Server    => "freja.serverbox.dk",
               Charset        => ISO_8859_1);

      end;

      ------------------------
      --  Text_Plain_Email  --
      ------------------------

      ---------------------
      --  Text_With_Attachment  --
      ----------------------------
--    Text_With_Attachment :
--    declare
--
--       A_File   : constant GNATCOLL.VFS.Virtual_File :=
--                    Locate_On_Path ("/home/thomas/test.txt");
--       Date     : Header;
--       From     : Header;
--       To       : Header;
--       MIME     : Header;
--       Subject  : Header;
--       CT       : Header;
--       CTE      : Header;
--       An_Email : Message := New_Message (Multipart_Mixed);
--       T_Payload : Message := New_Message (Text_Plain);
--       US       : Unbounded_String := Null_Unbounded_String;
--
--    begin
--
--       --  Set multipart boundaries
--       Set_Boundary (Msg      => An_Email,
--                     Boundary => AWS.Utils.Random_String (16));
--
--       New_Line;
--       Put_Line ("--> Text_With_Attachment Start <--");
--
--       --  First we set the text payload.
--       Set_Text_Payload (Msg       => T_Payload,
--                         Payload   => "Test ��� ���",
--                         Charset   => Charset_ISO_8859_1);
--
--       --  Delete all headers for T_Payload
--       Delete_Headers (Msg  => T_Payload,
--                       Name => "");
--
--       --  Add Content-Type and Content-Transfer-Encoding headers to
--       --  T_Payload.
--       CT := Create (Name    => Content_Type,
--                     Value   => Text_Plain);
--       Set_Param (H           => CT,
--                  Param_Name  => "charset",
--                  Param_Value => Charset_ISO_8859_1);
--       Add_Header (Msg => T_Payload,
--                   H   => CT);
--
--       CTE := Create (Name    => Content_Transfer_Encoding,
--                      Value   => "8bit");
--       Add_Header (Msg => T_Payload,
--                   H   => CTE);
--
--       --  Add T_Payload to the An_Email message.
--       Add_Payload (Msg     => An_Email,
--                    Payload => T_Payload,
--                    First   => True);
--
--       --  Then we add an attachment
--       Attach (Msg                  => An_Email,
--               Path                 => A_File,
--               MIME_Type            => AWS.MIME.Content_Type ("test.txt"),
--               Description          => "A description of the file",
--               Charset              => Charset_ISO_8859_1);
--
--       --  Set the MIME preamble
--       Set_Preamble
--         (Msg      => An_Email,
--          Preamble => "This is a multi-part message in MIME format.");
--
--       --  Adding the headers to An_Email
--       Date := Create (Name => "Date",
--                       Value => Format_Date (Date => Ada.Calendar.Clock));
--       Add_Header (Msg => An_Email,
--                   H   => Date);
--
--       From := Create (Name    => "From",
--                       Value   => "Thomas L�cke",
--                       Charset => Charset_ISO_8859_1);
--       Append (H       => From,
--               Value   => " <thomas@responsum.dk>");
--       Add_Header (Msg => An_Email,
--                   H   => From);
--
--       To := Create (Name    => "To",
--                     Value   => "Thomas L�cke",
--                     Charset => Charset_ISO_8859_1);
--       Append (H       => To,
--               Value   => " <tl@ada-dk-org>");
--       Add_Header (Msg => An_Email,
--                   H   => To);
--
--       MIME := Create (Name    => MIME_Version,
--                       Value   => "1.0");
--       Add_Header (Msg => An_Email,
--                   H   => MIME);
--
--       Subject := Create (Name    => "Subject",
--                          Value   => "Text with attachment ��� ���",
--                          Charset => Charset_ISO_8859_1);
--       Add_Header (Msg => An_Email,
--                   H   => Subject);
--
--       --  Finally we output the raw email.
--       To_String (Msg    => An_Email,
--                  Result => US);
--
--       Put_Line (To_String (US));
--
--       Put_Line ("--> Text_With_Attachment_End <--");
--
--    end Text_With_Attachment;

      ---------------------------------------
      --  Text_HTML_Multipart_Alternative  --
      ---------------------------------------
--    Text_HTML_Multipart_Alternative :
--    declare
--
--       Date     : Header;
--       From     : Header;
--       To       : Header;
--       MIME     : Header;
--       Subject  : Header;
--       CT       : Header;
--       CTE      : Header;
--       An_Email : Message := New_Message (Multipart_Alternative);
--       T_Payload : Message := New_Message (Text_Plain);
--       H_Payload : Message := New_Message (Text_Html);
--       US       : Unbounded_String := Null_Unbounded_String;
--
--    begin
--
--       --  Set multipart boundaries
--       Set_Boundary (Msg      => An_Email,
--                     Boundary => AWS.Utils.Random_String (16));
--
--       New_Line;
--       Put_Line ("--> Text_HTML_Multipart_Alternative Start <--");
--
--       --  First we set the text payload.
--       Set_Text_Payload (Msg       => T_Payload,
--                         Payload   => "Test ��� ���",
--                         Charset   => Charset_ISO_8859_1);
--
--       --  Delete whatever headers the Set_Text_Payload procedure might've
--       --  added.
--       Delete_Headers (Msg  => T_Payload,
--                       Name => "");
--
--       --  Add Content-Type and Content-Transfer-Encoding headers to
--       --  T_Payload.
--       CT := Create (Name    => Content_Type,
--                     Value   => Text_Plain);
--       Set_Param (H           => CT,
--                  Param_Name  => "charset",
--                  Param_Value => Charset_ISO_8859_1);
--       Add_Header (Msg => T_Payload,
--                   H   => CT);
--
--       CTE := Create (Name    => Content_Transfer_Encoding,
--                      Value   => "8bit");
--       Add_Header (Msg => T_Payload,
--                   H   => CTE);
--
--       --  Next we set the HTML payload.
--       Set_Text_Payload (Msg       => H_Payload,
--                         Payload   => "<b>Test</b> ��� ���",
--                         Charset   => Charset_ISO_8859_1);
--
--       --  Delete whatever headers the Set_Text_Payload procedure might've
--       --  added.
--       Delete_Headers (Msg  => H_Payload,
--                       Name => "");
--
--       --  Add Content-Type and Content-Transfer-Encoding headers to
--       --  H_Payload.
--       CT := Create (Name    => Content_Type,
--                     Value   => Text_Html);
--       Set_Param (H           => CT,
--                  Param_Name  => "charset",
--                  Param_Value => Charset_ISO_8859_1);
--       Add_Header (Msg => H_Payload,
--                   H   => CT);
--
--       CTE := Create (Name    => Content_Transfer_Encoding,
--                      Value   => "8bit");
--       Add_Header (Msg => H_Payload,
--                   H   => CTE);
--
--       --  Add T_Payload and H_Payload to the An_Email message.
--       Add_Payload (Msg     => An_Email,
--                    Payload => T_Payload,
--                    First   => True);
--       Add_Payload (Msg     => An_Email,
--                    Payload => H_Payload,
--                    First   => False);
--
--       --  Set the MIME preamble
--       Set_Preamble
--        (Msg      => An_Email,
--         Preamble => "This is a multi-part message in MIME format.");
--
--       --  Then we add the headers.
--       Date := Create (Name => "Date",
--                       Value => Format_Date (Date => Ada.Calendar.Clock));
--       Add_Header (Msg => An_Email,
--                   H   => Date);
--
--       From := Create (Name    => "From",
--                       Value   => "Thomas L�cke",
--                       Charset => Charset_ISO_8859_1);
--       Append (H       => From,
--              Value   => " <thomas@responsum.dk>");
--       Add_Header (Msg => An_Email,
--                   H   => From);
--
--       To := Create (Name    => "To",
--                     Value   => "Thomas L�cke",
--                     Charset => Charset_ISO_8859_1);
--       Append (H       => To,
--               Value   => " <tl@ada-dk-org>");
--       Add_Header (Msg => An_Email,
--                   H   => To);
--
--       MIME := Create (Name    => MIME_Version,
--                       Value   => "1.0");
--       Add_Header (Msg => An_Email,
--                   H   => MIME);
--
--       Subject := Create (Name    => "Subject",
--                          Value   => "Multipart_Alternative ��� ���",
--                          Charset => Charset_ISO_8859_1);
--       Add_Header (Msg => An_Email,
--                   H   => Subject);
--
--       --  Finally we output the raw email.
--       To_String (Msg    => An_Email,
--                  Result => US);
--
--       Put_Line (To_String (US));
--
--       Put_Line ("--> Text_HTML_Multipart_Alternative End <--");
--
--    end Text_HTML_Multipart_Alternative;

      ----------------------------------
      --  Multipart_Mixed_Attachment  --
      ----------------------------------
--    Multipart_Mixed_Attachment :
--    declare
--
--       SMTP              : constant AWS.SMTP.Receiver
--         := AWS.SMTP.Client.Initialize ("freja.serverbox.dk");
--       Status            : AWS.SMTP.Status;
--
--       A_File   : constant GNATCOLL.VFS.Virtual_File :=
--                    Locate_On_Path ("/home/thomas/test.txt");
--       B_File   : constant GNATCOLL.VFS.Virtual_File :=
--                    Locate_On_Path ("/home/thomas/test.odt");
--       Date     : Header;
--       From     : Header;
--       To       : Header;
--       MIME     : Header;
--       Subject  : Header;
--       CT       : Header;
--       CTE      : Header;
--       An_Email : Message := New_Message (Multipart_Mixed);
--       Alter    : Message := New_Message (Multipart_Alternative);
--       T_Payload : Message := New_Message (Text_Plain);
--       H_Payload : Message := New_Message (Text_Html);
--       US       : Unbounded_String := Null_Unbounded_String;
--
--    begin
--
--       --  Set multipart boundaries
--       Set_Boundary (Msg      => An_Email,
--                     Boundary => AWS.Utils.Random_String (16));
--       Set_Boundary (Msg      => Alter,
--                     Boundary => AWS.Utils.Random_String (16));
--
--       New_Line;
--       Put_Line ("--> Multipart_Mixed_Attachment Start <--");
--
--       --  First we set the text payload.
--       Set_Text_Payload (Msg       => T_Payload,
--                         Payload   => "Test ��� ���",
--                         Charset   => Charset_ISO_8859_1);
--
--       --  Delete whatever headers the Set_Text_Payload procedure might've
--       --  added.
--       Delete_Headers (Msg  => T_Payload,
--                       Name => "");
--
--       --  Add Content-Type and Content-Transfer-Encoding headers to
--       --  T_Payload.
--       CT := Create (Name    => Content_Type,
--                     Value   => Text_Plain);
--       Set_Param (H           => CT,
--                  Param_Name  => "charset",
--                  Param_Value => Charset_ISO_8859_1);
--       Add_Header (Msg => T_Payload,
--                   H   => CT);
--
--       CTE := Create (Name    => Content_Transfer_Encoding,
--                      Value   => "8bit");
--       Add_Header (Msg => T_Payload,
--                   H   => CTE);
--
--       --  Next we set the HTML payload.
--       Set_Text_Payload (Msg       => H_Payload,
--                         Payload   => "<b>Test</b> ��� ���",
--                         Charset   => Charset_ISO_8859_1);
--
--       --  Delete whatever headers the Set_Text_Payload procedure might've
--       --  added.
--       Delete_Headers (Msg  => H_Payload,
--                       Name => "");
--
--       --  Add Content-Type and Content-Transfer-Encoding headers to
--       --  H_Payload.
--       CT := Create (Name    => Content_Type,
--                     Value   => Text_Html);
--       Set_Param (H           => CT,
--                  Param_Name  => "charset",
--                  Param_Value => Charset_ISO_8859_1);
--       Add_Header (Msg => H_Payload,
--                   H   => CT);
--
--       CTE := Create (Name    => Content_Transfer_Encoding,
--                      Value   => "8bit");
--       Add_Header (Msg => H_Payload,
--                   H   => CTE);
--
--       --  Add T_Payload and H_Payload to the Alter message.
--       Add_Payload (Msg     => Alter,
--                    Payload => T_Payload,
--                    First   => True);
--       Add_Payload (Msg     => Alter,
--                    Payload => H_Payload,
--                    First   => False);
--
--           --  Add the Alter message to An_Email
--           Add_Payload (Msg     => An_Email,
--                        Payload => Alter,
--                        First   => True);
--
--       --  Then we add an attachment to An_Email
--       Attach (Msg                  => An_Email,
--               Path                 => A_File,
--               MIME_Type            => AWS.MIME.Content_Type ("test.txt"),
--               Description          => "A description of the file",
--               Charset              => Charset_ISO_8859_1);
--
--       --  And another attachment to An_Email
--       Attach (Msg                  => An_Email,
--               Path                 => B_File,
--               MIME_Type            => AWS.MIME.Content_Type ("test.odt"),
--               Description          => "An Openoffice file",
--               Charset              => Charset_ISO_8859_1);
--
--       --  Set the MIME preamble
--       Set_Preamble
--         (Msg      => An_Email,
--          Preamble => "This is a multi-part message in MIME format.");
--
--       --  Then we add the headers.
--       Date := Create (Name => "Date",
--                       Value => Format_Date (Date => Ada.Calendar.Clock));
--       Add_Header (Msg => An_Email,
--                   H   => Date);
--
--       From := Create (Name    => "From",
--                       Value   => "Thomas L�cke",
--                       Charset => Charset_ISO_8859_1);
--       Append (H       => From,
--               Value   => " <thomas@responsum.dk>");
--       Add_Header (Msg => An_Email,
--                   H   => From);
--
--       To := Create (Name    => "To",
--                     Value   => "Thomas L�cke",
--                     Charset => Charset_ISO_8859_1);
--       Append (H       => To,
--               Value   => " <tl@ada-dk-org>");
--       Add_Header (Msg => An_Email,
--                   H   => To);
--
--       MIME := Create (Name    => MIME_Version,
--                       Value   => "1.0");
--       Add_Header (Msg => An_Email,
--                   H   => MIME);
--
--       Subject := Create (Name    => "Subject",
--                          Value   => "Multipart_Mixed_Attachment ��� ���",
--                          Charset => Charset_ISO_8859_1);
--       Add_Header (Msg => An_Email,
--                   H   => Subject);
--
--       --  Finally we output the raw email.
--       To_String (Msg    => An_Email,
--                  Result => US);
--
--       Put_Line (To_String (US));
--
--       Put_Line ("--> Multipart_Mixed_Attachment End <--");
--
--       AWS.SMTP.Client.Send
--         (Server  => SMTP,
--          From    => AWS.SMTP.E_Mail (Name    => "Thomas L�cke",
--                                      Address => "thomas@responsum.dk"),
--          To      => AWS.SMTP.E_Mail (Name    => "Thomas L�cke",
--                                      Address => "tl@ada-dk.org"),
--          Subject => "Stuff",
--          Message => To_String (US),
--          Status  => Status);
--
--       if AWS.SMTP.Is_Ok (Status) then
--          Put_Line ("Email send!");
--       end if;
--
--    end Multipart_Mixed_Attachment;

      return Build_Response
        (Status_Data   => Request,
         Template_File => My.Config.Get (My.Template_Index),
         Translations  => T);

   end Generate;

end View.Index;

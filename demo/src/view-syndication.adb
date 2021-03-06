-------------------------------------------------------------------------------
--                                                                           --
--                   Copyright (C) 2010-, Thomas Løcke                   --
--                                                                           --
--  This is free software;  you can redistribute it and/or modify it         --
--  under terms of the  GNU General Public License  as published by the      --
--  Free Software  Foundation;  either version 3,  or (at your  option) any  --
--  later version. This library is distributed in the hope that it will be   --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of  --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     --
--  You should have received a copy of the GNU General Public License and    --
--  a copy of the GCC Runtime Library Exception along with this program;     --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
--  <http://www.gnu.org/licenses/>.                                          --
--                                                                           --
-------------------------------------------------------------------------------

with Ada.Calendar;
with Ada.Strings.Fixed;
with Yolk.Syndication.Writer;

package body View.Syndication is

   use Ada.Strings;
   use Ada.Strings.Fixed;
   use Yolk.Syndication.Writer;

   -------------------------
   --  Add_Entry_To_Feed  --
   -------------------------

   procedure Add_Entry_To_Feed
   is
      Feed_Entry : Atom_Entry                 := New_Atom_Entry;
      Now        : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      --  Populate the feed with an entry.
      Set_Title (Entr  => Feed_Entry,
                 Title => "Go Back To Demo Page [" &
                 Trim (Natural'Image (Amount_Of_Entries (Feed)), Left) & "]");

      Add_Link (Entr => Feed_Entry,
                Href => "/");

      Set_Id (Entr => Feed_Entry,
              Id   => "http://example.org/entry/id" &
              Trim (Natural'Image (Amount_Of_Entries (Feed)), Left));

      Set_Summary (Entr    => Feed_Entry,
                   Summary => "Hola!");

      Set_Published (Entr           => Feed_Entry,
                     Published_Time => Now);

      Set_Updated (Entr        => Feed_Entry,
                   Update_Time => Now);

      --  Add the entry to the feed.
      Add_Entry (Feed        => Feed,
                 Entr        => Feed_Entry,
                 Clear_Entry => True);
   end Add_Entry_To_Feed;

   ---------------
   --  Generate --
   ---------------

   function Generate
     (Request : in AWS.Status.Data)
      return AWS.Response.Data
   is
      use AWS.Response;
      use AWS.Status;

      Valid : Boolean := False;
      Value : Unbounded_String;
   begin
      Cache.Read (Key      => Feed_Data,
                  Is_Valid => Valid,
                  Value    => Value);

      if not Valid then
         Add_Entry_To_Feed;

         Set_Updated (Feed        => Feed,
                      Update_Time => Ada.Calendar.Clock);

         Value := To_Unbounded_String (Get_XML_String (Feed => Feed));

         Cache.Write (Key   => Feed_Data,
                      Value => Value);
      end if;

      return Build_Response
        (Status_Data => Request,
         Content     => To_String (Value),
         MIME_Type   => Text_XML);

   exception
      when Not_Valid_XML =>
         return Build_Response (Status_Data => Request,
                                Content     => "<p>XML not valid.</p>");
   end Generate;
begin
   --  Lets build the ATOM feed. This is a rather involved process, since there
   --  are quite a lot of XML elements to take care of in the ATOM RFC.
   --  The feed built here is not using all the available Atom elements, just
   --  the most basic ones.
   --
   --  This feed validates according to the W3C feed validator, except for the
   --  Self link, which is probably going to report a "Self reference doesn't
   --  match document location" error, for obvious reasons. You can find the
   --  validator here:
   --    http://validator.w3.org/feed/
   --
   --  The Atom RFC can be found here:
   --    http://tools.ietf.org/html/rfc4287

   --  Build the feed element.
   Set_Id (Feed => Feed,
           Id   => "http://example.org/feed/id");

   Set_Title (Feed  => Feed,
              Title => "The Yolk Atom Feed Demo");

   Add_Author (Feed => Feed,
               Name => "Thomas Løcke");

   Add_Category (Feed => Feed,
                 Term => "A Feed Category Term");

   Add_Contributor (Feed => Feed,
                    Name => "Trine Løcke");

   Set_Generator (Feed    => Feed,
                  Agent   => "Yolk Syndication",
                  Version => Version);

   Set_Icon (Feed => Feed,
             URI  => "http://example.org/icon");

   Add_Link (Feed => Feed,
             Href => "http://example.org/syndication",
             Rel  => Self);

   Set_Logo (Feed => Feed,
             URI  => "http://example.org/logo");

   Set_Rights (Feed   => Feed,
               Rights => "Some Rights");

   Set_Subtitle (Feed     => Feed,
                 Subtitle => "If you refresh the page, each 10 seconds a" &
                 " new entry is added, until a maximum of 10 entries.");

   Set_Updated (Feed        => Feed,
                Update_Time => Ada.Calendar.Clock);

end View.Syndication;

module output.app;

import Google.Apis.Drive.v3.DriveClient: DriveClient;
import Google.Apis.Drive.v3.Drive;
import Google.Apis.Drive.v3.Data.About: About;
import Google.Apis.Drive.v3.Data.File: File;
import Google.Apis.Drive.v3.Data.Comment: Comment;
import Google.Apis.Drive.v3.DriveScopes: Scopes, DriveScopes;

import std.stdio;
import requests;
import std.exception: enforce;

// modify with your own credentials file
enum string CREDENTIALS_FILE = "credentials.json";

// files to be uploaded
string[] toUpload = ["text.txt", "image.jpg", "curs.pdf"];

File[] listFiles(Drive _drive) {
    auto res = _drive.files().list_()
                             .setFields("files(id,name,mimeType,permissions,trashed)")
                             .setQ("trashed = false and mimeType != 'application/vnd.google-apps.folder'")
                             .execute();

    File[] files = res.getFiles();
    writeln("======================= List Files ==============================");
    foreach (file; files) {
        writeln("++++++++++++++++++++++++++");
        writeln("File: ", file.getName());
        writeln("Id: ", file.getId());
        writeln("Mime type: ", file.getMimeType());
        writeln("Permissions: ", file.getPermissions());
        writeln("++++++++++++++++++++++++++");
    }

    if (files.length == 0) {
        writeln("There are no files to be shown.");
    }

    writeln("======================= End List Files ===========================\n\n\n");

    return files;
}

void main() {
    //build drive service
    Drive _drive = new Drive(CREDENTIALS_FILE, Scopes.DRIVE);
    File[] files;

    listFiles(_drive);

    //std.stdio.stdin.readln();

    std.stdio.stdin.readln();

    // upload files
    {
        foreach (filename; toUpload) {
            File file = new File().setName(filename);
            std.stdio.File content = std.stdio.File("inputs/" ~ filename);
            auto res = _drive.files()
                             .create_!(Request, Response, std.stdio.File)(file, content)
                             .upload();
        }
    }

    // list files
    files = listFiles(_drive);
    string fileIdForComments = "";

    std.stdio.stdin.readln();

    // add comments to the text file uploaded
    {
        auto filesWithSpecifiedName = _drive.files().list_()
                                                    .setQ("name = 'text.txt'")
                                                    .setFields("files(id)")
                                                    .execute()
                                                    .getFiles();
        enforce(filesWithSpecifiedName.length > 0);
        
        fileIdForComments = filesWithSpecifiedName[0].getId();

        writeln(fileIdForComments);

        auto comm1 = _drive.comments()
                           .create_(fileIdForComments,
                                    Comment().setContent("This is the first comment."))
                           .setFields("*")
                           .execute();
        auto comm2 = _drive.comments()
                           .create_(fileIdForComments,
                                    Comment().setContent("This is the second comment."))
                           .setFields("*")
                           .execute();
    }

    // list comments
    {
        auto res = _drive.comments()
                         .list_(fileIdForComments)
                         .setFields("*")
                         .execute();
        writeln("=========================== Comments ============================");
        foreach (comment; res.getComments()) {
            writeln(comment.getContent());
        }
        writeln("=========================== End Comments ============================\n\n\n");
    }

    std.stdio.stdin.readln();

    // download files
    {
        foreach (file; files) {
            std.stdio.File downloadedFile = std.stdio.File("downloads/" ~ file.getName(), "w+");
            _drive.files.get_(file.getId()).mediaDownload(downloadedFile);
        }

        import std.file: dirEntries, SpanMode;
        writeln("=========================== Download files ============================");
        foreach (name; dirEntries("downloads", SpanMode.breadth)) {
            write(name ~ "\t");
        }
        writeln("\n======================= End downloaded files ======================\n\n\n");
    }

    std.stdio.stdin.readln();

    // delete file and check if it was deleted
    {
        foreach (file; files) {
            _drive.files().delete_(file.getId()).execute();
        }

        listFiles(_drive);
    }
}
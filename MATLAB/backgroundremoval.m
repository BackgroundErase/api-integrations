function background_removal(src, dst, api_key)
    % BACKGROUND_REMOVAL  Uploads an image to the Background Erase API and
    % shows before/after result side by side in MATLAB.
    %
    % Usage:
    %   background_removal('input.jpg', 'output.png', 'YOUR_API_KEY')

    if nargin < 3
        error('Usage: background_removal("input.jpg","output.png","YOUR_API_KEY")');
    end

    % Read the file and determine its type
    [~, fname, ext] = fileparts(src);

    % Read file as raw bytes (important for binary data)
    fid = fopen(src, 'rb');
    if fid == -1
        error('Cannot open input file: %s', src);
    end
    fileData = fread(fid, '*uint8')';
    fclose(fid);

    % Guess MIME type
    try
        ctype = matlab.net.internal.getMIMEType(ext);
    catch
        ctype = '';
    end
    if isempty(ctype)
        ctype = 'application/octet-stream';
    end

    % Generate multipart boundary and CRLF
    boundary = ['----' char(java.util.UUID.randomUUID())];
    CRLF = char([13 10]);

    % Build multipart body
    headerPart = sprintf(['--%s%s' ...
        'Content-Disposition: form-data; name="image_file"; filename="%s%s"' ...
        'Content-Type: %s%s%s'], ...
        boundary, CRLF, fname, ext, CRLF, ctype, CRLF, CRLF);

    footerPart = sprintf('%s--%s--%s', CRLF, boundary, CRLF);

    % Combine into one binary array
    body = [uint8(headerPart) fileData uint8(footerPart)];

    % HTTP headers
    headerFields = [ ...
        matlab.net.http.field.ContentTypeField(['multipart/form-data; boundary=' boundary]), ...
        matlab.net.http.HeaderField('x-api-key', api_key) ...
    ];

    % Build and send request
    req = matlab.net.http.RequestMessage('POST', headerFields, body);
    uri = matlab.net.URI('https://api.backgrounderase.net/v2');
    resp = send(req, uri);

    % Handle response
    if resp.StatusCode == matlab.net.http.StatusCode.OK
        % Save result
        fid = fopen(dst, 'wb');
        fwrite(fid, resp.Body.Data);
        fclose(fid);
        fprintf('✅ Saved: %s\n', dst);

        % Display original vs result
        figure('Name', 'Background Removal Result', 'NumberTitle', 'off');
        subplot(1,2,1);
        imshow(imread(src));
        title('Original');

        subplot(1,2,2);
        imshow(imread(dst));
        title('Background Removed');
    else
        fprintf('❌ %s\n', string(resp.StatusCode));
        if ~isempty(resp.Body.Data)
            disp(char(resp.Body.Data));
        end
    end
end

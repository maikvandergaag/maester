﻿<#
.SYNOPSIS
This is the main Maester command that runs the tests and generates a report of the results.

.DESCRIPTION
Using Invoke-Maester is the easiest way to run the Pester tests and generate a report of the results.

For more advanced configuration, you can directly use the Pester module and the Export-MtHtmlReport function.

By default, Invoke-Maester runs all *.Tests.ps1 files in the current directory and all subdirectories recursively.

.PARAMETER NoLogo
Do not show the Maester logo.

.PARAMETER NonInteractive
This will suppress the logo when Maester starts and prevent the test results from being opened in the default browser.

.EXAMPLE
Invoke-Maester

Runs all the test files under the current folder and generates a report of the results in the ./test-results folder.

.EXAMPLE
Invoke-Maester ./maester-tests

Runs all the tests in the folder ./tests/Maester and generates a report of the results in the default ./test-results folder.

.EXAMPLE
Invoke-Maester -Tag 'CA'

Runs the tests with the tag "CA" and generates a report of the results in the default ./test-results folder.

.EXAMPLE
Invoke-Maester -Tag 'CA', 'App'

Runs the tests with the tags 'CA' and 'App' and generates a report of the results in the default ./test-results folder.

.EXAMPLE
Invoke-Maester -OutputFolder './my-test-results'

Runs all the tests and generates a report of the results in the ./my-test-results folder.

.EXAMPLE
Invoke-Maester -OutputHtmlFile './test-results/TestResults.html'

Runs all the tests and generates a report of the results in the specified file.

.EXAMPLE
Invoke-Maester -Path ./tests/EIDSCA

Runs all the tests in the EIDSCA folder.

.EXAMPLE
Invoke-Maester -MailRecipient john@contoso.com

Runs all the tests and sends a report of the results to mail recipient.

.EXAMPLE
Invoke-Maester -TeamId '00000000-0000-0000-0000-000000000000' -TeamChannelId '19%3A00000000000000000000000000000000%40thread.tacv2'

Runs all the tests and posts a summary of the results to a Teams channel.

.EXAMPLE
Invoke-Maester -TeamChannelWebhookUri 'https://some-url.logic.azure.com/workflows/invoke?api-version=2016-06-01'

Runs all the tests and posts a summary of the results to a Teams channel.

.EXAMPLE
Invoke-Maester -Verbosity Normal

Shows results of tests as they are run including details on failed tests.

.EXAMPLE
```powershell
$configuration = New-PesterConfiguration
$configuration.Run.Path = './tests/Maester'
$configuration.Filter.Tag = 'CA'
$configuration.Filter.ExcludeTag = 'App'

Invoke-Maester -PesterConfiguration $configuration
```

Runs all the Pester tests in the EIDSCA folder.

.LINK
    https://maester.dev/docs/commands/Invoke-Maester
#>
function Invoke-Maester {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Colors are beautiful')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Incorrectly flags ExportCsv and ExportExcel as unused')]
    [Alias("Invoke-MtMaester")]
    [CmdletBinding()]
    param (
        # Specifies path to files containing tests. The value is a path\file name or name pattern. Wildcards are permitted.
        [Parameter(Position = 0)]
        [string] $Path,

        # Only run the tests that match this tag(s).
        [string[]] $Tag,

        # Exclude the tests that match this tag(s).
        [string[]] $ExcludeTag,

        # The path to the file to save the test results in html format. The filename should include an .html extension.
        [string] $OutputHtmlFile,

        # The path to the file to save the test results in markdown format. The filename should include a .md extension.
        [string] $OutputMarkdownFile,

        # The path to the file to save the test results in json format. The filename should include a .json extension.
        [string] $OutputJsonFile,

        # The folder to save the test results. If PassThru and no -Output* is set, defaults to ./test-results.
        # If set, other -Output* parameters are ignored and all formats will be generated (markdown, html, json)
        # with a timestamp and saved in the folder.
        [string] $OutputFolder,

        # The filename to use for all the files in the output folder. e.g. 'TestResults' will generate TestResults.html, TestResults.md, TestResults.json.
        [string] $OutputFolderFileName,

        # [PesterConfiguration] object for Advanced Configuration
        # Default is New-PesterConfiguration
        # For help on each option see New-PesterConfiguration, or inspect the object it returns.
        # See [Pester Configuration](https://pester.dev/docs/usage/Configuration) for more information.
        [PesterConfiguration] $PesterConfiguration,

        # Set the Pester verbosity level. Default is 'None'.
        # None: Shows only the final summary.
        # Normal: Focus on successful containers and failed tests/blocks. Shows basic discovery information and the summary of all tests.
        # Detailed: Similar to Normal, but this level shows all blocks and tests, including successful.
        # Diagnostic: Very verbose, but useful when troubleshooting tests. This level behaves like Detailed, but also enables debug-messages.
        [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
        [string] $Verbosity = 'None',

        # Run the tests in non-interactive mode. This will prevent the test results from being opened in the default browser.
        [switch] $NonInteractive,

        # Passes the output of the Maester tests to the console.
        [switch] $PassThru,

        # Optional. The email addresses of the recipients. e.g. john@contoso.com
        # No email will be sent if this parameter is not provided.
        [string[]] $MailRecipient,

        # Uri to the detailed test results page.
        [string] $MailTestResultsUri,

        # The user id or user principal name of the sender of the mail. Defaults to the current user.
        # This is required when using application permissions.
        [string] $MailUserId,

        # Optional. The Teams team where the test results should be posted.
        # To get the TeamId, right-click on the channel in Teams and select 'Get link to channel'. Use the value of groupId. e.g. ?groupId=<TeamId>
        [string] $TeamId,

        # Optional. The channel where the message should be posted. e.g. 19%3A00000000000000000000000000000000%40thread.tacv2
        # To get the TeamChannelId, right-click on the channel in Teams and select 'Get link to channel'. Use the value found between channel and the channel name. e.g. /channel/<TeamChannelId>/my%20channel
        [string] $TeamChannelId,

        # Optional. The webhook Uri where the message should be posted. e.g. https://some-url/?value=123
        # To get the Webhook Uri, right-click on the channel in Teams and select 'Workflow'. Create a workflow using the 'Post to a channel when a webhook request is received' template. Use the value after complete
        [string] $TeamChannelWebhookUri,

        # Skip the graph connection check.
        # This is used for running tests that does not require a graph connection.
        [switch] $SkipGraphConnect,

        # Disable Telemetry
        # If set, telemetry information will not be logged.
        [switch] $DisableTelemetry,

        # Skip the version check.
        # If set, the version check will not be performed.
        [switch] $SkipVersionCheck,

        # Export the results to a CSV file.
        [Parameter(HelpMessage = 'Export the results to a CSV file. Use with -OutputFolder to specify the folder.')]
        [switch] $ExportCsv,

        # Export the results to an Excel file.
        [Parameter(HelpMessage = 'Export the results to an Excel file. Use with -OutputFolder to specify the folder.')]
        [switch] $ExportExcel,

        # Do not show the Maester logo.
        [Parameter(HelpMessage = 'Do not show the logo when starting Maester.')]
        [switch] $NoLogo
    )

    function GetDefaultFileName() {
        $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        return "TestResults-$timestamp.html"
    }

    function ValidateAndSetOutputFiles($out) {
        $result = $null
        if (![string]::IsNullOrEmpty($out.OutputHtmlFile)) {
            if ($out.OutputHtmlFile.EndsWith(".html") -eq $false) {
                $result = "The OutputHtmlFile parameter must have an .html extension."
            }
        }
        if (![string]::IsNullOrEmpty($out.OutputMarkdownFile)) {
            if ($out.OutputMarkdownFile.EndsWith(".md") -eq $false) {
                $result = "The OutputMarkdownFile parameter must have an .md extension."
            }
        }
        if (![string]::IsNullOrEmpty($out.OutputJsonFile)) {
            if ($out.OutputJsonFile.EndsWith(".json") -eq $false) {
                $result = "The OutputJsonFile parameter must have a .json extension."
            }
        }

        $someOutputFileHasValue = ![string]::IsNullOrEmpty($out.OutputHtmlFile) -or `
            ![string]::IsNullOrEmpty($out.OutputMarkdownFile) -or ![string]::IsNullOrEmpty($out.OutputJsonFile)

        if ([string]::IsNullOrEmpty($out.OutputFolder) -and !$someOutputFileHasValue) {
            # No outputs specified. Set default folder.
            $out.OutputFolder = "./test-results"
        }

        if (![string]::IsNullOrEmpty($out.OutputFolder)) {
            # Create the output folder if it doesn't exist and generate filenames
            New-Item -Path $out.OutputFolder -ItemType Directory -Force | Out-Null # Create the output folder if it doesn't exist

            if ([string]::IsNullOrEmpty($out.OutputFolderFileName)) {
                # Generate a default filename
                $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
                $out.OutputFolderFileName = "TestResults-$timestamp"
            }

            $out.OutputHtmlFile = Join-Path $out.OutputFolder "$($out.OutputFolderFileName).html"
            $out.OutputMarkdownFile = Join-Path $out.OutputFolder "$($out.OutputFolderFileName).md"
            $out.OutputJsonFile = Join-Path $out.OutputFolder "$($out.OutputFolderFileName).json"

            if($ExportCsv.IsPresent) {
                $out.OutputCsvFile = Join-Path $out.OutputFolder "$($out.OutputFolderFileName).csv"
            }
            if($ExportExcel.IsPresent) {
                $out.OutputExcelFile = Join-Path $out.OutputFolder "$($out.OutputFolderFileName).xlsx"
            }
        }
        return $result
    }

    function GetPesterConfiguration($Path, $Tag, $ExcludeTag, $PesterConfiguration) {
        if (!$PesterConfiguration) {
            $PesterConfiguration = New-PesterConfiguration
        }

        $PesterConfiguration.Run.PassThru = $true
        $PesterConfiguration.Output.Verbosity = $Verbosity
        if ($Path) { $PesterConfiguration.Run.Path = $Path }
        else {
            if (Test-Path -Path "./powershell/tests/pester.ps1") {
                # Internal dev, exclude Maester's core tests
                $PesterConfiguration.Run.Path = "./tests"
            }
        }
        if ($Tag) { $PesterConfiguration.Filter.Tag = $Tag }
        if ($ExcludeTag) { $PesterConfiguration.Filter.ExcludeTag = $ExcludeTag }

        return $PesterConfiguration
    }

    $version = Get-MtModuleVersion

    if ( $NonInteractive.IsPresent -or $NoLogo.IsPresent ) {
        Write-Verbose "Running Maester v$Version"
    } else {
        # ASCII Art using style "ANSI Shadow"
        $motd = @"

███╗   ███╗ █████╗ ███████╗███████╗████████╗███████╗██████╗
████╗ ████║██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗
██╔████╔██║███████║█████╗  ███████╗   ██║   █████╗  ██████╔╝
██║╚██╔╝██║██╔══██║██╔══╝  ╚════██║   ██║   ██╔══╝  ██╔══██╗
██║ ╚═╝ ██║██║  ██║███████╗███████║   ██║   ███████╗██║  ██║
╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ v$version

"@
        Write-Host -ForegroundColor Green $motd
    }

    Clear-ModuleVariable # Reset the graph cache and urls to avoid stale data

    if (-not $DisableTelemetry) {
        Write-Telemetry -EventName InvokeMaester
    }

    $isMail = $null -ne $MailRecipient

    $isTeamsChannelMessage = -not ([String]::IsNullOrEmpty($TeamId) -or [String]::IsNullOrEmpty($TeamChannelId))

    $isWebUri = -not ([String]::IsNullOrEmpty($TeamChannelWebhookUri))

    if ($SkipGraphConnect) {
        Write-Host "🔥 Skipping graph connection check" -ForegroundColor Yellow
    } else {
        if (!(Test-MtContext -SendMail:$isMail -SendTeamsMessage:$isTeamsChannelMessage)) { return }
    }

    # Initialize after graph connected
    Initialize-MtSession

    if ($isWebUri) {
        # Check if TeamChannelWebhookUri is a valid URL
        $urlPattern = '^(https)://[^\s/$.?#].[^\s]*$'
        if (-not ($TeamChannelWebhookUri -match $urlPattern)) {
            Write-Output "Invalid Webhook URL: $TeamChannelWebhookUri"
            return
        }
    }

    $out = [PSCustomObject]@{
        OutputFolder         = $OutputFolder
        OutputFolderFileName = $OutputFolderFileName
        OutputHtmlFile       = $OutputHtmlFile
        OutputMarkdownFile   = $OutputMarkdownFile
        OutputJsonFile       = $OutputJsonFile
        OutputCsvFile        = $null
        OutputExcelFile      = $null
    }

    $result = ValidateAndSetOutputFiles $out

    if ($result) {
        Write-Error -Message $result
        return
    }

    # Only run CAWhatIf tests if explicitly requested
    if ("CAWhatIf" -notin $Tag) {
        $ExcludeTag += "CAWhatIf"
    }

    # If $Tag is not set, run all tests except the ones with the tag "Full"
    if (-not $Tag) {
        $ExcludeTag += "Full"
    } # Check if Full is included then add All to the include as default
    elseif ("Full" -in $Tag) {
        $Tag += "All"
    }

    $pesterConfig = GetPesterConfiguration -Path $Path -Tag $Tag -ExcludeTag $ExcludeTag -PesterConfiguration $PesterConfiguration
    $Path = $pesterConfig.Run.Path.value
    Write-Verbose "Merged configuration: $($pesterConfig | ConvertTo-Json -Depth 5 -Compress)"

    if ( Test-Path -Path $Path -PathType Leaf ) {
        Write-Host "The path '$Path' is a file. Please provide a folder path." -ForegroundColor Red
        Write-Host "💫 Update-MaesterTests" -NoNewline -ForegroundColor Green
        Write-Host " → Get the latest tests built by the Maester team and community." -ForegroundColor Yellow
        return
    }

    if ( -not ( Test-Path -Path $Path -PathType Container ) ) {
        Write-Host "The path '$Path' does not exist." -ForegroundColor Red
        Write-Host "💫 Update-MaesterTests" -NoNewline -ForegroundColor Green
        Write-Host " → Get the latest tests built by the Maester team and community." -ForegroundColor Yellow
        return
    }

    if ( -not ( Get-ChildItem -Path "$Path\*.Tests.ps1" -Recurse ) ) {
        Write-Host "No test files found in the path '$Path'." -ForegroundColor Red
        Write-Host "💫 Update-MaesterTests" -NoNewline -ForegroundColor Green
        Write-Host " → Get the latest tests built by the Maester team and community." -ForegroundColor Yellow
        return
    }

    $maesterResults = $null

    Set-MtProgressView
    Write-MtProgress -Activity "Starting Maester" -Status "Reading Maester config..." -Force
    Write-Verbose "Reading Maester config from: $Path"
    $__MtSession.MaesterConfig = Get-MtMaesterConfig -Path $Path

    Write-MtProgress -Activity "Starting Maester" -Status "Discovering tests to run..." -Force

    $pesterResults = Invoke-Pester -Configuration $pesterConfig

    if ($pesterResults) {

        Write-MtProgress -Activity "Processing test results" -Status "$($pesterResults.TotalCount) test(s)" -Force
        $maesterResults = ConvertTo-MtMaesterResult $PesterResults

        if (![string]::IsNullOrEmpty($out.OutputJsonFile)) {
            $maesterResults | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue | Out-File -FilePath $out.OutputJsonFile -Encoding UTF8
        }

        if (![string]::IsNullOrEmpty($out.OutputMarkdownFile)) {
            Write-MtProgress -Activity "Creating markdown report"
            $output = Get-MtMarkdownReport -MaesterResults $maesterResults
            $output | Out-File -FilePath $out.OutputMarkdownFile -Encoding UTF8
        }

        if (![string]::IsNullOrEmpty($out.OutputCsvFile)) {
            Write-MtProgress -Activity "Creating CSV"
            Convert-MtResultsToFlatObject -InputObject $maesterResults -CsvFilePath $out.OutputCsvFile
        }

        if (![string]::IsNullOrEmpty($out.OutputExcelFile)) {
            Write-MtProgress -Activity "Creating Excel workbook"
            Convert-MtResultsToFlatObject -InputObject $maesterResults -ExcelFilePath $out.OutputExcelFile
        }

        if (![string]::IsNullOrEmpty($out.OutputHtmlFile)) {
            Write-MtProgress -Activity "Creating html report"
            $output = Get-MtHtmlReport -MaesterResults $maesterResults
            $output | Out-File -FilePath $out.OutputHtmlFile -Encoding UTF8
            Write-Host "🔥 Maester test report generated at $($out.OutputHtmlFile)" -ForegroundColor Green

            if ( ( Get-MtUserInteractive ) -and ( -not $NonInteractive ) ) {
                # Open test results in default browser
                Invoke-Item $out.OutputHtmlFile | Out-Null
            }
        }

        if ($MailRecipient) {
            Write-MtProgress -Activity "Sending mail"
            Send-MtMail -MaesterResults $maesterResults -Recipient $MailRecipient -TestResultsUri $MailTestResultsUri -UserId $MailUserId
        }

        if ($TeamId -and $TeamChannelId) {
            Write-MtProgress -Activity "Sending Teams message"
            Send-MtTeamsMessage -MaesterResults $maesterResults -TeamId $TeamId -TeamChannelId $TeamChannelId -TestResultsUri $MailTestResultsUri
        }

        if ($TeamChannelWebhookUri) {
            Write-MtProgress -Activity "Sending Teams message"
            Send-MtTeamsMessage -MaesterResults $maesterResults -TeamChannelWebhookUri $TeamChannelWebhookUri -TestResultsUri $MailTestResultsUri
        }

        if ($Verbosity -eq 'None') {
            # Show final summary
            Write-Host "`nTests Passed ✅: $($pesterResults.PassedCount), " -NoNewline -ForegroundColor Green
            Write-Host "Failed ❌: $($pesterResults.FailedCount), " -NoNewline -ForegroundColor Red
            Write-Host "Skipped ⚫: $($pesterResults.SkippedCount)`n" -ForegroundColor DarkGray
        }

        if (-not $SkipVersionCheck -and 'Next' -ne $version) {
            # Don't check version if running in dev
            Get-IsNewMaesterVersionAvailable | Out-Null
        }

        Write-MtProgress -Activity "🔥 Completed tests" -Status "Total $($pesterResults.TotalCount) " -Completed -Force # Clear progress bar
    }
    Reset-MtProgressView
    if ($PassThru) {
        return $maesterResults
    }
}

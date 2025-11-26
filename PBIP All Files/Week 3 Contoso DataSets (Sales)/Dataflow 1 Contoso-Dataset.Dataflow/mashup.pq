[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared #"Sharepoint-Contoso" = "https://anzir.sharepoint.com/sites/OperationsTeam-InternalTrainings/" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true];
shared #"Sharepoint-folderpath-contoso" = "https://anzir.sharepoint.com/sites/OperationsTeam-InternalTrainings/Shared Documents/Internal Trainings/Harun/Week 3 + 4/Contoso Dataset/Dataset/" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true];
shared Source = let
    Source = SharePoint.Files(#"Sharepoint-Contoso", [ApiVersion = 15]),
    #"Filtered Rows" = Table.SelectRows(Source, each Text.Contains([Folder Path], #"Sharepoint-folderpath-contoso"))
in
    #"Filtered Rows";
shared FactInventory = let
    Source = Source,
    #"source folder" = Source{[Name="FactInventory.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=16, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"InventoryKey", Int64.Type}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed Type", {"ETLLoadID", "LoadDate", "UpdateDate"})
in
    #"Removed columns";
shared FactSales = let
    Source = Source,
    #"source folder" = Source{[Name="FactSales.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=19, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"SalesKey", Int64.Type}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed Type", {"ETLLoadID", "LoadDate", "UpdateDate"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"SalesAmount", Currency.Type}, {"DateKey", type datetime}, {"channelKey", Int64.Type}, {"StoreKey", Int64.Type}, {"ProductKey", Int64.Type}, {"PromotionKey", Int64.Type}, {"CurrencyKey", Int64.Type}, {"UnitCost", Currency.Type}, {"UnitPrice", Currency.Type}, {"SalesQuantity", Int64.Type}, {"ReturnQuantity", Int64.Type}, {"ReturnAmount", Currency.Type}, {"DiscountQuantity", Int64.Type}, {"DiscountAmount", Currency.Type}, {"TotalCost", Currency.Type}})
in
    #"Changed column type";
shared FactOnlineSales = let
    Source = Source,
    #"source folder" = Source{[Name="FactOnlineSales.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=21, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"OnlineSalesKey", Int64.Type}}),
  #"Removed columns" = Table.RemoveColumns(#"Changed Type", {"ETLLoadID", "LoadDate", "UpdateDate"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"DateKey", type datetime}, {"StoreKey", Int64.Type}, {"ProductKey", Int64.Type}, {"PromotionKey", Int64.Type}, {"CurrencyKey", Int64.Type}, {"CustomerKey", Int64.Type}, {"SalesOrderNumber", type text}, {"SalesOrderLineNumber", Int64.Type}, {"SalesQuantity", Int64.Type}, {"SalesAmount", type number}, {"ReturnQuantity", Int64.Type}, {"ReturnAmount", type number}, {"DiscountQuantity", Int64.Type}, {"DiscountAmount", type number}, {"TotalCost", type number}, {"UnitCost", type number}, {"UnitPrice", type number}})
in
    #"Changed column type";
shared FactSalesQuota = let
  Source = Source,
  #"source folder" = Source{[Name = "FactSalesQuota.csv", #"Folder Path" = #"Sharepoint-folderpath-contoso"]}[Content],
  #"Imported CSV" = Csv.Document(#"source folder", [Delimiter = ",", Columns = 13, Encoding = 65001, QuoteStyle = QuoteStyle.None]),
  #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Removed columns" = Table.RemoveColumns(#"Promoted Headers", {"ETLLoadID", "LoadDate", "UpdateDate"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"SalesQuotaKey", Int64.Type}, {"ChannelKey", Int64.Type}, {"StoreKey", Int64.Type}, {"ProductKey", Int64.Type}, {"DateKey", type datetime}, {"CurrencyKey", Int64.Type}, {"ScenarioKey", Int64.Type}, {"SalesQuantityQuota", Int64.Type}, {"SalesAmountQuota", type number}, {"GrossMarginQuota", type number}})
in
  #"Changed column type";
shared EndDate = #date(2024, 12, 31) meta [IsParameterQuery=true, Type="Date", IsParameterQueryRequired=true];
shared StartDate = #date(18, 1, 1) meta [IsParameterQuery=true, Type="Date", IsParameterQueryRequired=true];
shared #"Data For Which facts" = let
    ListDates = List.Dates(#"StartDate", Number.From(#"EndDate" - #"StartDate")+1, #duration(1,0,0,0)),
    #"Converted to Table" = Table.FromList(ListDates, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Date"}}),
    #"Added Calendar Date" = Table.AddColumn(#"Renamed Columns", "Calendar Date", each Date.AddMonths ([Date],#"Fiscal Year Reset")),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Calendar Date",{{"Date", type date}, {"Calendar Date", type date}}),
    #"Month Offset" = Table.AddColumn(#"Changed Type", "Month Offset", each (Date.Year([Date]) - Date.Year(Date.From(DateTime.LocalNow())))*12 
+ Date.Month([Date]) - Date.Month(Date.From(DateTime.LocalNow()))),
    #"Day Offset" = Table.AddColumn(#"Month Offset", "Day Offset", each Number.From((Date.From(DateTime.LocalNow()) - [Date])) * -1, type number),
    #"Year Offset" = Table.AddColumn(#"Day Offset", "Year Offset", each (Date.Year(Date.From(DateTime.LocalNow())) - Date.Year([Date])) * -1),
    #"Fiscal Year Offset" = Table.AddColumn(#"Year Offset", "Fiscal Year Offset", each if Date.Month(Date.From(DateTime.LocalNow())) > (12-#"Fiscal Year Reset")

then 
((Date.Year(Date.From(DateTime.LocalNow())) - Date.Year([Calendar Date])) * -1) -1

else 

(Date.Year(Date.From(DateTime.LocalNow())) - Date.Year([Calendar Date])) * -1),
    #"Inserted Calendar Year" = Table.AddColumn(#"Fiscal Year Offset", "Calendar Year", each Date.Year([Date])),
    #"Fiscal Year" = Table.AddColumn(#"Inserted Calendar Year", "Fiscal Year", each "FY" & Date.ToText([Calendar Date], "yy")),
    #"Changed Type1" = Table.TransformColumnTypes(#"Fiscal Year",{{"Year Offset", Int64.Type}, {"Calendar Year", type text}, {"Fiscal Year", type text}, {"Fiscal Year Offset", Int64.Type}}),
    PeriodNumberOfYear = Table.AddColumn(#"Changed Type1" , "PeriodNumberOfYear", each Date.Month([Calendar Date])),
    MonthNumberOfYear = Table.AddColumn(PeriodNumberOfYear, "MonthNumberOfYear", each Date.Month([Date]), Int64.Type),
    MonthLongName = Table.AddColumn(MonthNumberOfYear, "MonthLongName", each Date.MonthName([Date]), type text),
    MonthShortName = Table.AddColumn(MonthLongName, "MonthShortName", each Text.Start([MonthLongName], 3), type text),
    #"Month Status" = Table.AddColumn(MonthShortName, "Month Status", each if [Month Offset] = 0 then " Current" else if [Month Offset] > 0 then "Future" else "Complete"),
    Month = Table.AddColumn(#"Month Status", "Month", each [MonthShortName]
 &" '"& 
 Date.ToText([Date], "yy")),
    #"Fiscal Month" = Table.AddColumn(Month, "Fiscal Month", each [MonthShortName]
 &", "& 
[Fiscal Year]),
    #"Added LTM" = Table.AddColumn(#"Fiscal Month", "LTM", each if [Month Offset] > -13 and [Month Offset] < 0
 then "True"
 else "False"),
    #"Fiscal Quarter" = Table.AddColumn(#"Added LTM", "Quarter", each "Q"& Text.From(Date.QuarterOfYear([Calendar Date]))),
    #"Added QuarterNumberOfYear" = Table.AddColumn(#"Fiscal Quarter", "QuarterNumberOfYear", each Date.QuarterOfYear([Calendar Date])),
    #"Fiscal Quarter Year" = Table.AddColumn(#"Added QuarterNumberOfYear", "Fiscal Quarter", each [Quarter]
 &" '"& 
 [Fiscal Year]),
    #"Fiscal Quarter Offset" = Table.AddColumn(#"Fiscal Quarter Year", "Fiscal Quarter Offset", each ( Date.Year (Date.AddMonths([Date],#"Fiscal Year Reset")) 
  - 
   Date.Year(
       Date.From(Date.AddMonths( DateTime.LocalNow(), #"Fiscal Year Reset") )
            )
  )*4 

+ Date.QuarterOfYear (Date.AddMonths([Date],#"Fiscal Year Reset")) 

- Date.QuarterOfYear (Date.AddMonths( DateTime.LocalNow(), #"Fiscal Year Reset"))),
    #"Inserted DayOfMonth" = Table.AddColumn(#"Fiscal Quarter Offset", "DayOfMonth", each Date.Day([Date]), type number),
    #"Inserted Day Name" = Table.AddColumn(#"Inserted DayOfMonth", "Weekday", each Date.DayOfWeekName([Date]), type text),
    #"Inserted WeekdayShortName" = Table.AddColumn(#"Inserted Day Name", "WeekdayShortName", each Text.Start([Weekday], 3), type text),
    #"Inserted WeekDayNumber" = Table.AddColumn(#"Inserted WeekdayShortName", "WeekdayNumber", each Date.DayOfWeek([Date]), type number),
    IsWeekend = Table.AddColumn(#"Inserted WeekDayNumber", "IsWeekend", each Logical.From(if [WeekdayNumber]= 6 or [WeekdayNumber] = 0 then "TRUE" else "FALSE")),
    #"Inserted End of Week" = Table.AddColumn(IsWeekend, "StartOfWeek", each Date.StartOfWeek([Date], Day.Monday)),
    #"Added WeekName" = Table.AddColumn(#"Inserted End of Week", "WeekName", each Text.Combine
(
 {
  "Week of ",
  Date.ToText([StartOfWeek], "MMM"),

  "-",
  Date.ToText([StartOfWeek], "dd"),
  ", '",
  Date.ToText([StartOfWeek], "yy")
  }
)),
    #"Week Offset" = Table.AddColumn(#"Added WeekName", "Week Offset", each (
    Number.From((Date.From(Date.EndOfWeek(DateTime.LocalNow(), Day.Monday)) - [StartOfWeek]))
 * -1) 
 / 7),
    #"Half Year" = Table.AddColumn(#"Week Offset", "Half Year", each if Number.RoundUp([PeriodNumberOfYear]/6)=1
then "1st Half"
else "2nd Half"),
    #"Fiscal Half Year" = Table.AddColumn(#"Half Year", "Fiscal Half Year", each [Fiscal Year]&" "&[Half Year]),
    #"Fiscal Half Year Offset" = Table.AddColumn(#"Fiscal Half Year", "Fiscal Half Year Offset", each [Fiscal Year Offset]*2

+ 
Number.RoundUp(
(Date.Month([Calendar Date]) - Date.Month(Date.From(DateTime.LocalNow())))/6
)-1),
    #"Changed Type2" = Table.TransformColumnTypes(#"Fiscal Half Year Offset",{{"Week Offset", type number}}),
    #"Rounded Down" = Table.TransformColumns(#"Changed Type2",{{"Week Offset", Number.RoundDown, Int64.Type}}),
    #"Sorted Rows" = Table.Sort(#"Rounded Down",{{"Date", Order.Ascending}}),
    #"Removed Other Columns" = Table.SelectColumns(#"Sorted Rows",{"Date", "Month Offset", "Day Offset", "Year Offset", "Fiscal Year Offset", "Calendar Year", "Fiscal Year", "PeriodNumberOfYear", "MonthNumberOfYear", "MonthLongName", "MonthShortName", "Month Status", "Month", "Fiscal Month", "LTM", "Quarter", "QuarterNumberOfYear", "Fiscal Quarter", "Fiscal Quarter Offset", "DayOfMonth", "Weekday", "WeekdayShortName", "WeekdayNumber", "IsWeekend", "StartOfWeek", "WeekName", "Week Offset", "Half Year", "Fiscal Half Year", "Fiscal Half Year Offset"}),
    #"Reordered Columns" = Table.ReorderColumns(#"Removed Other Columns",{"Date", "Calendar Year", "Year Offset", "Fiscal Year", "Fiscal Year Offset", "Month", "Fiscal Month", "Month Offset", "Month Status", "LTM", "PeriodNumberOfYear", "MonthNumberOfYear", "MonthLongName", "MonthShortName", "Fiscal Quarter", "Quarter", "QuarterNumberOfYear", "Fiscal Quarter Offset", "StartOfWeek", "WeekName", "Week Offset", "Day Offset", "DayOfMonth", "Weekday", "WeekdayShortName", "WeekdayNumber", "IsWeekend"}),
    #"Changed Type3" = Table.TransformColumnTypes(#"Reordered Columns",{{"Calendar Year", type text}, {"Year Offset", Int64.Type}, {"Fiscal Year", type text}, {"Fiscal Year Offset", Int64.Type}, {"Month Status", type text}, {"Fiscal Month", type text}, {"Month", type text}, {"Month Offset", Int64.Type}, {"LTM", type logical}, {"PeriodNumberOfYear", Int64.Type}, {"MonthNumberOfYear", Int64.Type}, {"MonthLongName", type text}, {"MonthShortName", type text}, {"Fiscal Quarter", type text}, {"Quarter", type text}, {"QuarterNumberOfYear", Int64.Type}, {"Fiscal Quarter Offset", Int64.Type}, {"Week Offset", Int64.Type}, {"StartOfWeek", type text}, {"WeekName", type text}, {"Day Offset", Int64.Type}, {"DayOfMonth", Int64.Type}, {"WeekdayNumber", Int64.Type}, {"Weekday", type text}, {"WeekdayShortName", type text}, {"IsWeekend", type logical}, {"Half Year", type text}, {"Fiscal Half Year", type text}, {"Fiscal Half Year Offset", Int64.Type}}),
    #"Sorted Rows1" = Table.Sort(#"Changed Type3",{{"Date", Order.Descending}})
in
    #"Sorted Rows1";
shared DimChannel = let
    Source = Source,
    #"source folder" = Source{[Name="DimChannel.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"ChannelKey", Int64.Type}, {"ChannelLabel", Int64.Type}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Changed Type", {{"ETLLoadID", Int64.Type}, {"LoadDate", type datetime}, {"UpdateDate", type datetime}}),
  #"Removed other columns" = Table.SelectColumns(#"Changed column type", {"ChannelKey", "ChannelLabel", "ChannelName", "ChannelDescription"})
in
    #"Removed other columns";
shared DimCustomer = let
    Source = Source,
    #"source folder" = Source{[Name="DimCustomer.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=29, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
  #"Removed columns" = Table.RemoveColumns(#"Promoted Headers", {"UpdateDate", "LoadDate", "ETLLoadID", "CompanyName", "CustomerType", "Phone", "AddressLine2", "AddressLine1", "NumberCarsOwned", "HouseOwnerFlag", "NumberChildrenAtHome"})
in
    #"Removed columns";
shared DimStore = let
    Source = Source,
    #"source folder" = Source{[Name="DimStore.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=25, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
  #"Removed other columns" = Table.SelectColumns(#"Promoted Headers", {"StoreKey", "GeographyKey", "StoreManager", "StoreType", "StoreName", "StoreDescription", "Status", "ZipCode"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed other columns", {{"StoreKey", Int64.Type}, {"GeographyKey", Int64.Type}, {"StoreManager", Int64.Type}, {"StoreType", type text}, {"StoreName", type text}, {"StoreDescription", type text}, {"Status", type text}, {"ZipCode", type text}})

in
    #"Changed column type";
shared DimScenario = let
    Source = Source,
    #"source folder" = Source{[Name="DimScenario.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
  #"Removed columns" = Table.RemoveColumns(#"Promoted Headers", {"ETLLoadID", "LoadDate", "UpdateDate"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"ScenarioKey", Int64.Type}, {"ScenarioLabel", Int64.Type}, {"ScenarioName", type text}, {"ScenarioDescription", type text}})

in
    #"Changed column type";
shared DimGeography = let
    Source = Source,
    #"source folder" = Source{[Name="DimGeography.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=11, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
  #"Removed other columns" = Table.SelectColumns(#"Promoted Headers", {"GeographyKey", "ContinentName", "CityName", "StateProvinceName", "RegionCountryName"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed other columns", {{"GeographyKey", Int64.Type}, {"ContinentName", type text}, {"CityName", type text}, {"StateProvinceName", type text}, {"RegionCountryName", type text}})
    

in
    #"Changed column type";
shared DimProduct = let
    Source = Source,
    #"source folder" = Source{[Name="DimProduct.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=32, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
  #"Removed columns" = Table.RemoveColumns(#"Promoted Headers", {"ColorID", "ClassID", "StyleID", "UpdateDate", "LoadDate", "ETLLoadID", "ProductURL", "ImageURL", "AvailableForSaleDate", "StockTypeID", "Weight", "WeightUnitMeasureID", "UnitOfMeasureID", "UnitOfMeasureName"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"ProductKey", Int64.Type}, {"ProductLabel", Int64.Type}, {"ProductName", type text}, {"ProductDescription", type text}, {"ProductSubcategoryKey", Int64.Type}, {"Manufacturer", type text}, {"BrandName", type text}, {"ClassName", type text}, {"StyleName", type text}, {"ColorName", type text}, {"Size", type text}, {"SizeRange", type text}, {"SizeUnitMeasureID", type text}, {"StockTypeName", type text}, {"UnitCost", type number}, {"UnitPrice", type number}, {"StopSaleDate", type text}, {"Status", type text}})

in
    #"Changed column type";
shared DimProductCategory = let
    Source = Source,
    #"source folder" = Source{[Name="DimProductCategory.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=7, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
  #"Removed columns" = Table.RemoveColumns(#"Promoted Headers", {"ETLLoadID", "LoadDate", "UpdateDate"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"ProductCategoryKey", Int64.Type}, {"ProductCategoryLabel", Int64.Type}, {"ProductCategoryName", type text}, {"ProductCategoryDescription", type text}})

in
    #"Changed column type";
shared DimProductSubCategory = let
    Source = Source,
    #"source folder" = Source{[Name="DimProductSubcategory.csv",#"Folder Path"=#"Sharepoint-folderpath-contoso"]}[Content],
    #"Imported CSV" = Csv.Document(#"source folder",[Delimiter=",", Columns=8, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars=true]),
  #"Removed columns" = Table.RemoveColumns(#"Promoted Headers", {"ETLLoadID", "LoadDate", "UpdateDate"}),
  #"Changed column type" = Table.TransformColumnTypes(#"Removed columns", {{"ProductSubcategoryKey", Int64.Type}, {"ProductSubcategoryLabel", Int64.Type}, {"ProductSubcategoryName", type text}, {"ProductSubcategoryDescription", type text}, {"ProductCategoryKey", Int64.Type}})

in
    #"Changed column type";

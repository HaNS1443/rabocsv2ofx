for %%x in (*.pl) do (
for %%y in (*.csv) do perl %%x %%y > %%~ny.qif)
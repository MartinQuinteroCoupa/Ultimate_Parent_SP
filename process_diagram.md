# UltimateParentSP - Process Diagram

Visual guide of `[aic_data].[dbo].[UltimateParentSP]`. See `UltimateParentSP_Instructions.txt` for details.

```mermaid
flowchart TD
    A(["EXEC UltimateParentSP @client_db_name"]) --> B{"luUParent exists?"}
    B -- No --> C["Step 0: Create luUParent"]
    B -- Yes --> D
    C --> D["Step 1: Top 100 suppliers in tblRefresh by SUM of Spend"]
    D --> E["Step 2: Keep suppliers not in luUParent, into gptUParent"]
    E --> F{"New suppliers?"}
    F -- No --> J
    F -- Yes --> G["Step 2.1: GenAIConnection suggests Ultimate Parent"]
    G --> H{"GenAI answer"}
    H -- "Parent name" --> I1["Append to luUParent, Source = AI"]
    H -- "UNKNOWN" --> I2["Append to luUParent with NULL parent, for manual review"]
    H -- "Error or empty" --> I3["Not saved, retried next run"]
    I1 --> J
    I2 --> J
    I3 --> J
    J["Step 3: Update tblRefresh Ultimate Parent for all suppliers in luUParent"] --> K(["Print run log"])

    M[/"Manual corrections in luUParent, Source = Manual"/] -.-> J
```

| Table | Role |
|---|---|
| `tblRefresh` | Monthly source data. `[Ultimate Parent]` is populated by the procedure. |
| `luUParent` | Lookup table, one row per `[Normalized Supplier]`. Grows with each run. |
| `gptUParent` | Staging table for the GenAI call. Re-created on every run. |

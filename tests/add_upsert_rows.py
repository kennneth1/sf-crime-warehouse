import pandas as pd 

def insert_new_test_row(df):
    insert_row = df.sample(1).copy()
    insert_row["Row ID"] = 999999001
    insert_row["Incident Number"] = 999999001
    insert_row["Incident Code"] = 9999
    insert_row["Incident Category"] = "Robbery"
    df = pd.concat([df, insert_row], ignore_index=True)

    return df

def update_existing_row(df):
    # Pick an existing row
    update_idx = df.index[0]

    print("Updating original row:")
    print(
        df.loc[
            update_idx,
            ["Row ID", "Incident Number", "Incident Code", "Incident Category"]
        ]
    )

    # DO NOT change merge keys
    df.loc[update_idx, "Incident Category"] = "Robbery"
    df.loc[update_idx, "data_loaded_at"] = "2026-07-08 00:00:00"

    print("\nAfter update:")
    print(
        df.loc[
            update_idx,
            [
                "Row ID",
                "Incident Number",
                "Incident Code",
                "Incident Category",
                "data_loaded_at"
            ]
        ]
    )

    return df


def main():
    df = pd.read_csv("sf_crime.csv")

    df = insert_new_test_row(df)
    df = update_existing_row(df)

    df.to_csv(
        "sf_crime_incremental_test.csv",
        index=False
    )

    print("Saved incremental test CSV")


if __name__ == "__main__":
    main()
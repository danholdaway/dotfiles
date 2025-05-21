from netCDF4 import Dataset

def compare_netcdf_variables(file1, file2):
    """
    Compare variables in two NetCDF files.

    Parameters:
        file1 (str): Path to the first NetCDF file.
        file2 (str): Path to the second NetCDF file.

    Returns:
        tuple: A tuple containing:
            - common_vars (list): Variables present in both files.
            - unique_to_file1 (list): Variables unique to file1.
            - unique_to_file2 (list): Variables unique to file2.
    """
    # Open the NetCDF files
    with Dataset(file1, 'r') as nc1, Dataset(file2, 'r') as nc2:
        # Get the variable names in each file
        vars_file1 = set(nc1.variables.keys())
        vars_file2 = set(nc2.variables.keys())

    # Find common and unique variables
    common_vars = sorted(vars_file1.intersection(vars_file2))
    unique_to_file1 = sorted(vars_file1 - vars_file2)
    unique_to_file2 = sorted(vars_file2 - vars_file1)

    return common_vars, unique_to_file1, unique_to_file2

if __name__ == "__main__":
    # Example usage
    file1 = input("Enter the path to the first NetCDF file: ")
    file2 = input("Enter the path to the second NetCDF file: ")

    common_vars, unique_to_file1, unique_to_file2 = compare_netcdf_variables(file1, file2)

    print("\nVariables common to both files:")
    for var in common_vars:
        print(f" - {var}")

    print("\nVariables unique to file1:")
    for var in unique_to_file1:
        print(f" - {var}")

    print("\nVariables unique to file2:")
    for var in unique_to_file2:
        print(f" - {var}")

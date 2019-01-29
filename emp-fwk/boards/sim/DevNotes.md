# Development notes

## MP7 top level constants and declarations

MP7 projects rely on 3 declaration files

* `mp7_brd_decl`: design-specific declarations, i.e. N of regions, design id, etc.
* `mp7_top_decl`: a mixture of constants, basic types and parameterised types
* `top_decl`: project level parameters

The first step towards a clean user interface is to clarify their role and refactor them as appropriate with easy-to understand names.

* `mp7_brd_decl`: For multi-fpga boards the element `brd` is confusing. `design` seems a better naming choice. Proposal: `emp_device_decl`
* `mp7_top_decl`: I find the cohexistence of basic and parameterised data types confusing. The basic types are common to all desings, which suggests that they belong to a common definition package (`emp_framework_decl`)  which shoudl include `FRAMEWORK_REV` as well. The parameterized types would then defined in `emp_device_types`. 
* `top_decl`: The name is a little ambiguous. `emp_project_decl` o `emp_proj_top_decl` would be possibly clearer, indicating that this is project specific

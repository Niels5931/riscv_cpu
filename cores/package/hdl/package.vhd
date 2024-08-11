library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package types is
    type arr is array (integer range <>) of std_logic_vector;
    FUNCTION "+" (L : std_logic_vector; R : std_logic_vector) RETURN std_logic_vector;
    FUNCTION "+" (L : std_logic_vector; R : integer) RETURN std_logic_vector;
    FUNCTION "-" (L : std_logic_vector; R : std_logic_vector) RETURN std_logic_vector;
    FUNCTION "-" (L : std_logic_vector; R : integer) RETURN std_logic_vector;
    FUNCTION ">" (L : std_logic_vector; R : integer) RETURN BOOLEAN;
    FUNCTION "<" (L : std_logic_vector; R : integer) RETURN BOOLEAN;
    FUNCTION "=" (L : std_logic_vector; R : integer) RETURN BOOLEAN;
end package;

package body types is
    
   FUNCTION "+" (L : std_logic_vector; R : std_logic_vector) RETURN std_logic_vector is
   begin
   return std_logic_vector(unsigned(L) + unsigned(R));
   END FUNCTION;
   
   FUNCTION "+" (L : std_logic_vector; R : integer) RETURN std_logic_vector is
   begin
   return std_logic_vector(unsigned(L) + R);
   END FUNCTION;
   
   FUNCTION "-" (L : std_logic_vector; R : std_logic_vector) RETURN std_logic_vector is
   begin
   return std_logic_vector(unsigned(L) - unsigned(R));
   END FUNCTION;
   
   FUNCTION "-" (L : std_logic_vector; R : integer) RETURN std_logic_vector is
   begin
   return std_logic_vector(unsigned(L) - R);
   END FUNCTION;
   
   FUNCTION ">" (L : std_logic_vector; R : integer) RETURN BOOLEAN is
   begin
        if TO_INTEGER(unsigned(L)) > R then
            RETURN TRUE;
        else
            RETURN FALSE;    
        end if;   
   END FUNCTION;

   FUNCTION "<" (L : std_logic_vector; R : integer) RETURN BOOLEAN is
    begin
          if TO_INTEGER(unsigned(L)) < R then
                RETURN TRUE;
          else
                RETURN FALSE;    
          end if;   
    END FUNCTION;
    
   FUNCTION "=" (L : std_logic_vector; R : integer) RETURN BOOLEAN is
   begin
        if TO_INTEGER(unsigned(L)) = R then
            RETURN TRUE;
        else
            RETURN FALSE;    
        end if;   
   END FUNCTION;

end package body;
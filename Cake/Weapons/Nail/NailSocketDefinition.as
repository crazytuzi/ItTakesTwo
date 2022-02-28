
enum ENailSocketDefinition
{
	NailWeapon_HandCatch,
	NailWeapon_HandThrow,
	NailWeapon_Quiver,
	NailWeapon_Root,
};

UFUNCTION()
FName GetNailSocketNameFromDefinition(ENailSocketDefinition Input)
{
	switch (Input)
	{
	case ENailSocketDefinition::NailWeapon_HandCatch:
		return FName("NailCatchSocket");
		// return FName("LeftAttach");
	case ENailSocketDefinition::NailWeapon_HandThrow:
		return FName("RightAttach");
	case ENailSocketDefinition::NailWeapon_Quiver:
		return FName("NailSocket");
	case ENailSocketDefinition::NailWeapon_Root:
		return FName("None");
	}
	devEnsure(false, "ERROR: Name definitions haven't been updated everywhere in SocketDefintions.as");
	return NAME_None;
}
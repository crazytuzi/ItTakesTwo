
enum EHammerSocketDefinition
{
	HammerWeapon_Hand,
	HammerWeapon_Back
};

UFUNCTION()
FName GetHammerSocketNameFromDefinition(EHammerSocketDefinition Input)
{
	switch (Input)
	{
	case EHammerSocketDefinition::HammerWeapon_Hand:
		return FName("RightAttach");
	case EHammerSocketDefinition::HammerWeapon_Back:
		return FName("Hammer_Socket");
	}
	devEnsure(false, "ERROR: Name definitions haven't been updated everywhere in SocketDefintions.as");
	return NAME_None;
}
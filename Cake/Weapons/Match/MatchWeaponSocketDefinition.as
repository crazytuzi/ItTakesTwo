
enum EMatchWeaponSocketDefinition
{
	WielderRightHandSocket,
	WielderLeftHandSocket,
	WielderQuiverSocket,
	MatchCrossbowSocket,
	StartWeaponTraceSocket
};

UFUNCTION()
FName GetMatchWeaponSocketNameFromDefinition(EMatchWeaponSocketDefinition Input)
{
	switch (Input)
	{
	case EMatchWeaponSocketDefinition::WielderRightHandSocket:
		return FName("RightAttach");
	case EMatchWeaponSocketDefinition::WielderLeftHandSocket:
		return FName("LeftAttach");
	case EMatchWeaponSocketDefinition::WielderQuiverSocket:
  		return FName("WS_Socket");
	case EMatchWeaponSocketDefinition::MatchCrossbowSocket:
		return FName("Match");
	case EMatchWeaponSocketDefinition::StartWeaponTraceSocket:
		return FName("StartWeaponTrace");
	}
	devEnsure(false, "ERROR: Name definitions haven't been updated everywhere in EMatchWeaponSocketDefinition.as");
	return NAME_None;
}

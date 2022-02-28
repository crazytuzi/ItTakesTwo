import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspShell;

class UWaspShieldTeam : UHazeAITeam
{
	TArray<UStaticMesh> UsedShieldVariants;

	UStaticMesh SelectShieldVariant(const TArray<UStaticMesh>& AvailableShield)
	{
		if (AvailableShield.Num() == 0)
			return nullptr;

		UStaticMesh Shield = nullptr;
		int Offset = FMath::RandRange(0, AvailableShield.Num() - 1);
		for (int i = 0; i < AvailableShield.Num(); i++)
		{
			Shield = AvailableShield[(i + Offset) % AvailableShield.Num()];
			if (!UsedShieldVariants.Contains(Shield))
				break;
			Shield = nullptr;
		}

		if (Shield == nullptr)
		{
			// All have been used at least once, start anew
			UsedShieldVariants.Empty(UsedShieldVariants.Num());
			Shield = AvailableShield[Offset % AvailableShield.Num()];
		}

		if (Shield != nullptr)
			UsedShieldVariants.Add(Shield);
		return Shield;
	}
}
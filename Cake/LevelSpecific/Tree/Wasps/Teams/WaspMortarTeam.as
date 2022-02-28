class UWaspMortarTeam : UHazeAITeam
{
	TArray<USkeletalMesh> UsedArmourVariants;

	USkeletalMesh SelectArmourVariant(const TArray<USkeletalMesh>& AvailableArmour)
	{
		if (AvailableArmour.Num() == 0)
			return nullptr;

		USkeletalMesh Armour = nullptr;
		int Offset = FMath::RandRange(0, AvailableArmour.Num() - 1);
		for (int i = 0; i < AvailableArmour.Num(); i++)
		{
			Armour = AvailableArmour[(i + Offset) % AvailableArmour.Num()];
			if (!UsedArmourVariants.Contains(Armour))
				break;
			Armour = nullptr;
		}

		if (Armour == nullptr)
		{
			// All have been used at least once, start anew
			UsedArmourVariants.Empty(UsedArmourVariants.Num());
			Armour = AvailableArmour[Offset % AvailableArmour.Num()];
		}

		if (Armour != nullptr)
			UsedArmourVariants.Add(Armour);
		return Armour;
	}
}
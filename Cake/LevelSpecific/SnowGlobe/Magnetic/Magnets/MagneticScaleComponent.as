// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// //event void FOnScaleStateChanged(bool Active, UMagneticScaleComponent Component);
// UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
// class UMagneticScaleComponent : UMagneticComponent
// {
// 	bool bActivated = false;
// 	TArray<AHazePlayerCharacter> UsingPlayers;
// 	TArray<bool> bOpposite;

// 	//UPROPERTY()
// 	//FOnScaleStateChanged OnScaleStateChanged;

// 	UFUNCTION()
// 	void ActivateMagneticInteraction(AHazePlayerCharacter PlayerUsingScale, bool IsOpposite)
// 	{
// 		bActivated = true;
// 		bOpposite.Add(IsOpposite);
// 		UsingPlayers.Add(PlayerUsingScale);
// 		//OnScaleStateChanged.Broadcast(true, this);
// 	}

// 	UFUNCTION()
// 	void DeactivateMagneticInteraction(AHazePlayerCharacter PlayerWhoUsedScale)
// 	{
// 		int Index = UsingPlayers.FindIndex(PlayerWhoUsedScale);
// 		bOpposite.RemoveAt(Index);
// 		UsingPlayers.Remove(PlayerWhoUsedScale);

// 		if(UsingPlayers.Num() <= 0)
// 		{
// 			//OnScaleStateChanged.Broadcast(false, this);
// 			bActivated = false;
// 		}
// 	}
// }
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
// class UMagneticPullcordComponent : UMagneticComponent
// {
// 	bool bActivated = false;
// 	TArray<AHazePlayerCharacter> UsingPlayers;
// 	TArray<bool> bOpposite;

// 	UFUNCTION()
// 	void ActivateMagneticInteraction(AHazePlayerCharacter PlayerUsingScale, bool IsOpposite)
// 	{
// 		bActivated = true;
// 		bOpposite.Add(IsOpposite);
// 		UsingPlayers.Add(PlayerUsingScale);
// 	}

// 	UFUNCTION()
// 	void DeactivateMagneticInteraction(AHazePlayerCharacter PlayerWhoUsedScale)
// 	{
// 		int Index = UsingPlayers.FindIndex(PlayerWhoUsedScale);
// 		bOpposite.RemoveAt(Index);
// 		UsingPlayers.Remove(PlayerWhoUsedScale);

// 		if(UsingPlayers.Num() <= 0)
// 		{
// 			bActivated = false;
// 		}
// 	}

// 	bool IsMagneticPathBlocked(AHazePlayerCharacter Player, UMagneticComponent MagneticComponent) const
// 	{
// 		FHitResult Hit;
// 		TArray<AActor> ActorsToIgnore;
// 		ActorsToIgnore.Add(Game::GetCody());
// 		ActorsToIgnore.Add(Game::GetMay());
// 		System::LineTraceSingle(WorldLocation, MagneticComponent.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true, FLinearColor::Green);

// 		if(Hit.bBlockingHit)
// 		{
// 			return true;
// 		}
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
//     EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query)const
//     {
// 		if(bIsDisabled)
// 		{
// 			return EHazeActivationPointStatusType::InvalidAndHidden;
// 		}
// 		else if(DisabledForObjects.Contains(Player))
// 		{
// 			return EHazeActivationPointStatusType::InvalidAndHidden;	
// 		}
		
//         UMagneticComponent PlayerMagComponent = UMagneticComponent::Get(Player);

// 		if (IsMagneticPathBlocked(Player, PlayerMagComponent))
// 		{
// 			return EHazeActivationPointStatusType::Invalid;
// 		}
		   
//         return Super::SetupActivationStatus(Player, Query);
//     }
// }
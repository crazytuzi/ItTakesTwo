// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// event void FOnWheelStateChanged(bool Active, UMagnetWheelComponent Component);

// UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
// class UMagnetWheelComponent : UMagneticComponent
// {
// 	bool bActivated = false;

// 	TArray<AHazePlayerCharacter> UsingPlayers;
// 	TArray<bool> bPushing;

// 	UPROPERTY()
// 	FOnWheelStateChanged OnWheelStateChanged;

// 	UFUNCTION()
// 	void ActivateMagneticInteraction(AHazePlayerCharacter Player, bool IsOpposite)
// 	{
// 		if(!bActivated)
// 		{
// 			bActivated = true;
// 			OnWheelStateChanged.Broadcast(true, this);
// 		}
		
// 		UsingPlayers.Add(Player);
// 		bPushing.Add(IsOpposite);
// 	}

// 	UFUNCTION()
// 	void DeactivateMagneticInteraction(AHazePlayerCharacter Player)
// 	{
// 		float PlayerIndex = UsingPlayers.FindIndex(Player);
// 		bPushing.RemoveAt(PlayerIndex);
// 		UsingPlayers.Remove(Player);

// 		if(UsingPlayers.Num() <= 0)
// 		{
// 			OnWheelStateChanged.Broadcast(false, this);
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
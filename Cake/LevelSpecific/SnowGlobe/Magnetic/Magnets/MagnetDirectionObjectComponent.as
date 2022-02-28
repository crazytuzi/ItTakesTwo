// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
// class UMagnetDirectionObjectComponent : UMagneticComponent
// {
// 	UPROPERTY()
// 	USceneComponent HorizontalAimComponent;

// 	UPROPERTY()
// 	USceneComponent VerticalAimComponent;

// 	UPROPERTY()
// 	USceneComponent PointOfInterestComponent;

// 	UPROPERTY()
// 	UHazeCameraSettingsDataAsset CameraSettings;

// 	TArray<AHazePlayerCharacter> UsingPlayers;
// 	TArray<bool> bPushing;

// 	bool bActivated = false;
	
// 	bool IsMagneticPathBlocked(AHazePlayerCharacter Player, UMagneticComponent MagneticComponent) const
// 	{
// 		FHitResult Hit;
// 		TArray<AActor> ActorsToIgnore;
// 		ActorsToIgnore.Add(Player);
// 		System::LineTraceSingle(WorldLocation, MagneticComponent.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false, FLinearColor::Green);

// 		if(Hit.bBlockingHit)
// 		{
// 			return true;
// 		}
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
//     EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, const FHazeQueriedActivationPoint& Query)const
//     {
//         UMagneticComponent PlayerMagComponent = UMagneticComponent::Get(Player);

// 		if (IsMagneticPathBlocked(Player, PlayerMagComponent))
// 		{
// 			return EHazeActivationPointStatusType::Invalid;
// 		}
		   
//         return Super::SetupActivationStatus(Player, Query);
//     }
// }
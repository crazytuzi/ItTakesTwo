// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
// class UDefaultMagneticComponent : UMagneticComponent
// {
// 	bool bFreeSightWithSelfIncluded = false;
// 	bool bFreeSightWithSelfInculdedIfOpposite = false;

// 	bool IsMagneticPathBlocked(AHazePlayerCharacter Player, UMagneticComponent MagneticComponent) const
// 	{
// 		FHitResult Hit;
// 		TArray<AActor> ActorsToIgnore;
// 		ActorsToIgnore.Add(Game::GetCody());
// 		ActorsToIgnore.Add(Game::GetMay());
// 		System::LineTraceSingle(WorldLocation, MagneticComponent.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false, FLinearColor::Green);

// 		if(Hit.bBlockingHit)
// 		{
// 			return true;
// 		}
// 		return false;
// 	}


// 	UFUNCTION(BlueprintOverride)
//     EHazeActivationPointStatusType CanBeActivatedBy(AHazePlayerCharacter Player)const
//     {
		
// 		if(bIsDisabled)
// 		{
// 			return EHazeActivationPointStatusType::InvalidAndHidden;
// 		}
// 		else if(DisabledForObjects.Contains(Player))
// 		{
// 			return EHazeActivationPointStatusType::InvalidAndHidden;	
// 		}
		
// 		// We test the free sight
// 		if(!HasSightToTarget(Player))
// 		{
// 			if(!HasSightToTarget(Player, bTestFromCamera = true, SphereRadius = 50.f))
// 			{
// 				return EHazeActivationPointStatusType::InvalidAndHidden;
// 			}
// 		}

// 		else if(bFreeSightWithSelfIncluded)
// 		{
//        		// UMagneticComponent PlayerMagComponent = UMagneticComponent::Get(Player);
// 			// if (IsMagneticPathBlocked(Player, PlayerMagComponent))
// 			// {
// 			// 	return EHazeActivationPointStatusType::Invalid;
// 			// }

// 		}

// 		else if(bFreeSightWithSelfInculdedIfOpposite)
// 		{

// 		}


	
// 		return EHazeActivationPointStatusType::Valid;   
//         //return Super::CanBeActivatedBy(Player);
//     }
// }
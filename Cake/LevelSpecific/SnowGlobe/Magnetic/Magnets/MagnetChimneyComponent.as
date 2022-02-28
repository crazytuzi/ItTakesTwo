
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticMoveableComponent;

// UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
// class UMagneticChimneyComponent : UMagneticMoveableComponent
// {
// 	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 6000.f);
// 	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 3000.f);
// 	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 700.f);

// 	UFUNCTION(BlueprintOverride)
// 	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query)const
// 	{
// 		const EHazeActivationPointStatusType WantedActivationStatus = Super::SetupActivationStatus(Player, Query);
// 		if(WantedActivationStatus == EHazeActivationPointStatusType::Valid)
// 		{
// 			if (!IsBehindLid(Player))
// 				return EHazeActivationPointStatusType::Invalid;
// 		}

// 		return WantedActivationStatus;
// 	}

// 	bool IsBehindLid(AHazePlayerCharacter Player) const
// 	{
// 		FVector DirectionToPlayer = GetWorldLocation() - Player.ActorLocation;
// 		DirectionToPlayer.Z = 0;
// 		DirectionToPlayer.Normalize();
// 		float DotTolid = ForwardVector.DotProduct(DirectionToPlayer);

// 		if (DotTolid > 0)
// 		{
// 			return true;
// 		}

// 		else
// 		{
// 			return false;
// 		}
// 	}

// 	bool CanPlayerKeepInfluencing(AHazePlayerCharacter Player) override
// 	{
// 		return IsBehindLid(Player);
// 	}
// }

// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;


// // this component gives you a boost or a grab depending on the polarity
// UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
// class UMagneticMoveableComponent : UMagneticComponent
// {
// 	TArray<AHazePlayerCharacter> PlayersInfluencingObject;

// 	bool CanPlayerKeepInfluencing(AHazePlayerCharacter Player)
// 	{
// 		float DistanceToPlayer = Player.ActorLocation.Distance(Owner.ActorLocation);

// 		if (DistanceToPlayer < (GetDistance(EHazeActivationPointDistanceType::Selectable) * 2))
// 		{
// 			return true;
// 		}

// 		else
// 		{
// 			return false;
// 		}
		
// 	}
// }
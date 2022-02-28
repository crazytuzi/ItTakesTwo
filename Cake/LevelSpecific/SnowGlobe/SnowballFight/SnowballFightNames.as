namespace SnowballFightTags
{
	const FName Aim = n"SnowballFightAim";
	const FName Throw = n"SnowballFightThrow";
	const FName Hit = n"SnowballFightHit";

	const FName MiniGameStart = n"SnowballFightStartCapability";
}

namespace SnowballFightAction
{
	const FName Hit = n"SnowballFightProjectileHit";
}

namespace SnowballFightAttribute
{
	const FName HitVelocity = n"SnowballFightProjectileHitVelocity";
	const FName HitInstigator = n"SnowballFightProjectileHitInstigator";
	const FName ManagerComponent = n"SnowballFightManagerComponent";
}

struct FSnowballFightTargetData
{
	USceneComponent Component = nullptr;
	FVector RelativeLocation = FVector::ZeroVector;
	bool bIsWithinCollision = false;

	AActor GetActor() const
	{
		if (Component != nullptr)
			return Component.Owner;
			
		return nullptr;
	}

	FVector GetWorldLocation() const
	{
		auto Owner = GetActor();

		if (Component != nullptr && Owner != nullptr)
			return Owner.ActorTransform.TransformPosition(RelativeLocation);

		return RelativeLocation;
	}
}
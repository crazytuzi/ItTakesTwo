event void FPickupActionNoParams();

event void FPickupRotationLerp(FPickupRotationLerpParams PickupRotationLerpParams);
event void FPickupOffsetLerp(FPickupOffsetLerpParams PickupOffsetLerpParams);

event void FPlayerWantsToPutdown(FPutdownParams PutdownParams);
event void FForceDropRequested(FForceDropParams ForceDropParams);

event void FPickupThrowCollisionEvent(FVector LastTracedVelocity, const FHitResult& CollisionHit);

enum EPutdownType
{
	// Don't worry about it
	None,

	// Player is grounded and will put pickupable in front
	Ground,

	// Player is grounded and will step backwards to drop pickupable where he stands
	GroundInPlace,

	// Drop from air - Needs some animation love
	// NOT BEING USED AT THE MOMENT
	Air,

	// Places object at Player location - doesn't work with collision-enabled objects
	// NOT BEING USED AT THE MOMENT
	Teleport,

	// Will immediately drop pickupable without animation
	Cancelled
};

USTRUCT()
struct FPickupRotationLerpParams
{
	UPROPERTY()
	FQuat TargetRotation = FQuat::Identity;

	UPROPERTY()
	float LerpSpeed = 10.f;

	UPROPERTY()
	bool bWorldRotation = true;

	FPickupRotationLerpParams(FQuat Rotation, float Speed = 10.f, bool bIsWorldRotation = true)
	{
		TargetRotation = Rotation;
		LerpSpeed = Speed;
		bWorldRotation = bIsWorldRotation;
	}
};

USTRUCT()
struct FPickupOffsetLerpParams
{
	UPROPERTY()
	AHazePlayerCharacter PlayerCharacter;

	UPROPERTY()
	float LerpSpeed = 10.f;

	FPickupOffsetLerpParams(AHazePlayerCharacter Player, float Speed = 10.f)
	{
		PlayerCharacter = Player;
		LerpSpeed = Speed;
	}
}

USTRUCT()
struct FPutdownParams
{
	UPROPERTY()	
	FPutdownOverrideParams OverrideParams;

	UPROPERTY()
	EPutdownType PutdownType = EPutdownType::None;

	UPROPERTY()
	FRotator PlayerTargetPutdownRotation = FRotator::ZeroRotator;

	UPROPERTY()
	FVector PutdownLocation = FVector::ZeroVector;

	void Reset()
	{
		OverrideParams = FPutdownOverrideParams();

		PutdownType = EPutdownType::None;
		PlayerTargetPutdownRotation = FRotator::ZeroRotator;
		PutdownLocation = FVector::ZeroVector;
	}
}

USTRUCT()
struct FForceDropParams
{
	UPROPERTY()	
	FPutdownOverrideParams OverrideParams;

	UPROPERTY()
	bool bShouldPlayAnimation;

	FForceDropParams(bool bShouldPlayPutdownAnimation)
	{
		bShouldPlayAnimation = bShouldPlayPutdownAnimation;
	}

	FForceDropParams(FVector WorldPutdownLocation, bool bMovePlayerNextToPutdownLocation, bool bShouldPlayPutdownAnimation)
	{
		bShouldPlayAnimation = bShouldPlayPutdownAnimation;

		OverrideParams.bUsePutdownLocation = true;
		OverrideParams.PutdownLocation = WorldPutdownLocation;

		OverrideParams.bMovePlayerNextToPutdownLocation = bMovePlayerNextToPutdownLocation;
	}

	FForceDropParams(FVector WorldPutdownLocation, FRotator WorldPutdownRotationOverride, bool bMovePlayerNextToPutdownLocation, bool bShouldPlayPutdownAnimation)
	{
		bShouldPlayAnimation = bShouldPlayPutdownAnimation;

		OverrideParams.bUsePutdownLocation = true;
		OverrideParams.PutdownLocation = WorldPutdownLocation;

		OverrideParams.bUsePutdownRotation = true;
		OverrideParams.PutdownRotation = WorldPutdownRotationOverride;

		OverrideParams.bMovePlayerNextToPutdownLocation = bMovePlayerNextToPutdownLocation;
	}
}

USTRUCT()
struct FPutdownOverrideParams
{
	UPROPERTY()
	bool bUsePutdownLocation = false;

	UPROPERTY()
	FVector PutdownLocation = FVector::ZeroVector;


	UPROPERTY()
	bool bUsePutdownRotation = false;

	UPROPERTY()
	FRotator PutdownRotation = FRotator::ZeroRotator;


	UPROPERTY()
	bool bMovePlayerNextToPutdownLocation;
}

enum EPickupThrowType
{
	Controlled,
	UnrealPhysics
}

class UPickupThrowParams : UObject
{
	FPickupThrowCollisionEvent OnPickupThrowCollision;

	FVector ThrowVelocity;
	FVector Gravity;

	float Time;
}
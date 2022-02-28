import Cake.LevelSpecific.Clockwork.BullMiniBoss.ClockworkBullBossTags;

// EVENTS
event void FBullBossImpactActorEventSignature(AActor ImpactOnActor);
event void FBullBossImpactPillarEventSignature();
event void FBullBossKillPlayerEventSignature();
event void FBullBossActionEvent(EBullBossEventTags Type);
event void FOnChargeStateChangeSignature(EBullBossChargeStateType NewState);

enum EClockworkBullBossPillarStatus
{
	UnTouched,
    FirstSmash,
    SecondMash,
};

enum EBullBossMoveToLocationType
{
	Movement,
    PlayerLock,
    PlayerTeleportation,
};

struct FBullTargetLocation
{
	EBullBossMoveToLocationType LockedType = EBullBossMoveToLocationType::Movement;
	FVector Location = FVector::ZeroVector;
	FVector InitialDirectionToThis = FVector::ZeroVector;
	float LastDistance = -1.f;
	float LingerTimeLeft = 0.25f;
	float ValidationDistance = 0.f;
};


struct FBullAttackRangeChange
{
	UPROPERTY()
	float IncreasedAttackRange = 0;

	UPROPERTY()
	float IncreasedAttackRangeDuration = 0;
};

enum EBullBossDamageInstigatorType
{
	None,
	Head,
    LeftBackFoot,
    RightBackFoot,
	LeftFrontFoot,
	RightFrontFoot,	
	Torso,
};

enum EBullBossDamageType
{
	Stomp,
    LeftForce,
    RightForce,
	MovementDirectionForce,	
};

enum EBullBossDamageAmountType
{
	VerySmall,
	Small,
    Medium,
    Large,
	Huge,
};

// The amount is the percentage of the life meter
float GetBullBossDamageAmount(EBullBossDamageAmountType DamageAmountType)
{
	if(DamageAmountType == EBullBossDamageAmountType::VerySmall)
		return 0.2f;
	else if(DamageAmountType == EBullBossDamageAmountType::Small)
		return 0.4f;
	else if(DamageAmountType == EBullBossDamageAmountType::Large)
		return 0.5f;	
	else if(DamageAmountType == EBullBossDamageAmountType::Huge)
		return 0.8f;	
	else
		return 0.5f;	
}

enum EBullBossChargeStateType
{
	Inactive,
	MovingToChargePosition,
	TargetingMay,
	RushingMay,
	TargetingForward,
    RushingForward,
	ImpactWithMay,
	ImpactWithPillar,
	ImpactWithWall,
};


class UBullImpactComponent : USceneComponent
{
	UPROPERTY()
	float Radius = 100;

	UPROPERTY()
	float HalfHeight = 0;

	UPROPERTY()
	FName AttachBoneName = NAME_None;

	// If used, the rotation for the capsule will use this instead
	UPROPERTY()
	FName RotationBoneName = NAME_None;

	UPROPERTY()
	FRotator OffsetRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}
}


struct FBullAttackCollisionData
{
	FBullAttackCollisionData(UBullImpactComponent In, EBullBossDamageInstigatorType Instigator)
	{
		CollisionComponent = In;
		InstigatorType = Instigator;
	}

	bool IsCollisionEnabled()const
	{
		return bEnabled;
	}

	FVector2D GetCollisionSize()const
	{
		FVector2D FinalSize;
		FinalSize.X += CollisionComponent.Radius;
		FinalSize.Y += CollisionComponent.HalfHeight;

		FinalSize.X += BonusRadius.X;
		if(FinalSize.Y > 0)
			FinalSize.Y += BonusRadius.Y;

		return FinalSize;
	}

	FHazeIntersectionCapsule GetCapsule()const
	{
		FHazeIntersectionCapsule OutCapsule;
		FQuat AttachRotation = CollisionComponent.GetComponentQuat();
		
		// We have another bone that we should take the rotation from
		if(CollisionComponent.RotationBoneName != NAME_None)
		{
			auto Mesh = UHazeCharacterSkeletalMeshComponent::Get(CollisionComponent.Owner);
			AttachRotation = Mesh.GetSocketQuaternion(CollisionComponent.RotationBoneName);
			
			OutCapsule.MakeUsingOrigin(CollisionComponent.WorldLocation, AttachRotation.Rotator(), GetCollisionSize());
		}

		// We have a bone offset rotation
		if(!CollisionComponent.OffsetRotation.IsNearlyZero())
		{
			AttachRotation = AttachRotation * FQuat(CollisionComponent.OffsetRotation);
		}
		
		OutCapsule.MakeUsingOrigin(CollisionComponent.WorldLocation, AttachRotation.Rotator(), GetCollisionSize());

		return OutCapsule;
	}

	FHazeIntersectionSphere GetSphere()const
	{
		FHazeIntersectionSphere Out;
		Out.Origin = CollisionComponent.WorldLocation;
		Out.Radius = GetCollisionSize().X;
		return Out;
	}

	bool bEnabled = false;
	EBullBossDamageInstigatorType InstigatorType = EBullBossDamageInstigatorType::None;
	UBullImpactComponent CollisionComponent = nullptr;
	FVector2D BonusRadius;
	EBullBossDamageType DamageType = EBullBossDamageType::MovementDirectionForce;
	FVector DamageForce = FVector::ZeroVector;
	float ApplyForceTime = 0;
	float LockedIntoTakeDamageTime = -1;	
	float DamageAmount = 0;
};

struct FBullValidImpactData
{
	EBullBossDamageInstigatorType DamageInstigator = EBullBossDamageInstigatorType::Head;
	EBullBossDamageType DamageType = EBullBossDamageType::MovementDirectionForce;
	FVector DamageForce = FVector::ZeroVector;
	float ApplyForceTime = 0;
	float LockedIntoTakeDamageTime = -1;
	float DamageAmount = 0;
	bool bFromCharge = false;
};

struct FBullDebugText
{
	float TimeLeft;
	FString Text;
}

enum EBullBossAnimationDistance
{
	Close,
	MediumClose,
	Far
}

struct FBullBossAttackReplicationParams
{
	UPROPERTY()
	int RandomAttack;

	UPROPERTY()
	int RandomAttack2;

	UPROPERTY()
	int RandomAttack3;

	UPROPERTY()
	int AnimationVariation;

	UPROPERTY()
	EBullBossAnimationDistance DistanceToTargetType;
}

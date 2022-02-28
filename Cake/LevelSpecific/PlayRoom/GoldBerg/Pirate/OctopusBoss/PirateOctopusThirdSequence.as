import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusSlam;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusSequence;

enum EOctopusThirdPhaseState
{
	PhaseOne,
	PhaseTwo
};

class UPirateOctopusThirdSequenceComponent : UPirateOctopusSequenceComponent
{
	default NumberOfPoints = 36;

	EOctopusThirdPhaseState OctopusThirdPhaseState;

	bool FindWallStartPoint(FVector BoatLocation, int& OutFoundIndex)
	{
		const FVector DirToBossFromBoat = (Boss.GetActorLocation() - BoatLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		int BestIndex = -1;
		float ClosestAngle = -2;
		for(int i = 0; i < Points.Num(); ++i)
		{
			if(Points[i].CurrentArm != nullptr)
				continue;

			FVector WorldLocation = Points[i].SplinePosition.WorldLocation;
			const FVector DirToBossFromArm = (Boss.GetActorLocation() - WorldLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

			const float DotAngle = DirToBossFromArm.DotProduct(DirToBossFromBoat);

			if(DotAngle > ClosestAngle)
			{
				ClosestAngle = DotAngle;
				BestIndex = i;

				// Close enough to be the best
				if(DotAngle > 0.99)
					break;
			}
		}

		if(BestIndex >= 0)
		{
			OutFoundIndex = BestIndex;
			return true;
		}

		return false;
	}
}

UCLASS(Abstract)
class APirateOctopusThirdSequenceSlam : APirateOctopusSequenceSlamArm
{
	UPROPERTY(DefaultComponent, Attach = ArmBase)
	UCapsuleComponent ArmSlamCollider;
	default ArmSlamCollider.CapsuleHalfHeight = 3000.f;
	default ArmSlamCollider.CapsuleRadius = 500.f;
	default ArmSlamCollider.bGenerateOverlapEvents = false;

	default OffsetTowardBoatAmount = 3500.f;
	default EmergeOffset = 8000.f;

	default DamageAmount = 3.0f;

	default FollowBoatComponent.bFollowBoat = false;

	const float OffsetBetweenArms = 5000.f;

	bool bCanApplyDamage = false;

	float CurrentArmPositionIndexOffsetAlpha = -1;

	UPirateOctopusThirdSequenceComponent ThirdSequenceComponet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();

		EnemyComponent.AddBeginOverlap(ArmSlamCollider, this, n"BeginOverlapDamage");
		EnemyComponent.AddEndOverlap(ArmSlamCollider, this, n"EndOverlapDamage");
	}

	void ActivateArm() override
	{
		Super::ActivateArm();
		FollowBoatComponent.bFollowBoat = false;
	}

	void Initialize(AHazeActor BossActor, UHazeSplineComponent Stream) override
	{
		Super::Initialize(BossActor, Stream);
		ThirdSequenceComponet = UPirateOctopusThirdSequenceComponent::Get(Boss);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void BeginOverlapDamage(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		bCanApplyDamage = true;
	}

	UFUNCTION(NotBlueprintCallable)
	protected void EndOverlapDamage(UPrimitiveComponent OverlappedComponent, AWheelBoatActor Boat)
	{
		bCanApplyDamage = false;
		
	}

	bool CanApplyDamage()const override
	{
		return bCanApplyDamage;
	}

	FVector GetWantedWorldPosition(FVector WorldPosition) const override
	{
		const FVector BossLocation = Boss.GetActorLocation();
		const FVector DirToTarget = (BossLocation - WorldPosition).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		const FVector SideDir = DirToTarget.CrossProduct(FVector::UpVector);
		
		FVector FinalWorldPosition = WorldPosition;
		FinalWorldPosition += DirToTarget * OffsetTowardBoatAmount;
		FinalWorldPosition += (SideDir * OffsetBetweenArms * CurrentArmPositionIndexOffsetAlpha);
		return FinalWorldPosition;
	}

	void FinishAttack() override
	{
		Super::FinishAttack();
		ThirdSequenceComponet.RemoveArmFromPoint(this);
	}
}
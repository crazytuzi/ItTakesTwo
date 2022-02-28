import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusSlam;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusSequence;

class UPirateOctopusSecondSequenceComponent : UPirateOctopusSequenceComponent
{
	bool bArmDied = false;

	bool FindOccupiedPoint(FTransform BoatTransform, float InsideAngle, int& OutFoundIndex, bool bUseRandomInRange = true)
	{
		int BestIndex = -1;
		float ClosestAngle = -1;
		const FVector BoatLocation = BoatTransform.Location;
		const FVector BoatDirection = BoatTransform.Rotation.ForwardVector;
		TArray<int> ValidIndices;
		for(int i = 0; i < Points.Num(); ++i)
		{
			if(Points[i].CurrentArm == nullptr)
				continue;

			const FVector DirToPoint = (Points[i].SplinePosition.WorldLocation - BoatLocation).GetSafeNormal();
			const float DotAngle = Math::DotToDegrees(DirToPoint.DotProduct(BoatDirection));
			if(InsideAngle >= 0 && DotAngle > InsideAngle)
				continue;

			auto SeqArm = Cast<APirateOctopusSecondSequenceSlamArm>(Points[i].CurrentArm);
			if(SeqArm.IsMoving())
				continue;

			ValidIndices.Add(i);

			if(DotAngle > ClosestAngle)
			{
				BestIndex = i;
				ClosestAngle = DotAngle;
			}
		}

		if(ValidIndices.Num() > 0 && bUseRandomInRange && FMath::RandBool())
		{
			OutFoundIndex = ValidIndices[FMath::RandRange(0, ValidIndices.Num() - 1)];
			return true;
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
class APirateOctopusSecondSequenceSlamArm : APirateOctopusSequenceSlamArm //Uses a duck mesh
{
	default OffsetTowardBoatAmount = 1000.f;
	default FollowBoatComponent.DistanceOffset = 0;
	default FollowBoatComponent.ZOffset = 0;

	UPROPERTY(EditDefaultsOnly, Category = "Slam")
	FHazeMinMax MoveSpeed = FHazeMinMax(600.f, 1000.f);

	UPROPERTY(EditDefaultsOnly, Category = "Slam")
	UNiagaraSystem ExplodeEffect;
	//default ExplodeEffect.SetTranslucentSortPriority(3);

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DuckEmergeEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DuckExplodeEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ExplosionEvent;

	FHazeAudioEventInstance DuckEmergeEventInstance;

	UPROPERTY(NotEditable)
	float DistanceToBoat = 1.0f;

	float StartDistanceToBoat = 0.0f;
	
	UPROPERTY(NotEditable)
	bool bExploding = false;

	private UPirateOctopusSecondSequenceComponent SecondSequenceComp;

	void Initialize(AHazeActor BossActor, UHazeSplineComponent Stream) override
	{
		Super::Initialize(BossActor, Stream);
		SecondSequenceComp = UPirateOctopusSecondSequenceComponent::Get(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);
		AWheelBoatActor Boat = Cast<AWheelBoatActor>(PlayerTarget);
		const FVector DeltaToBoat = Boat.BoatMesh.GetWorldLocation() - GetActorLocation();
		//const FRotator WantedRotation = FollowBoatComponent.FindRotationTowardsTarget(GetActorLocation(), Boat);
		if(bAttacking)
		{
			const float SpeedAlpha = 1.f - Math::GetNormalizedDotProduct(DeltaToBoat.GetSafeNormal(), Boat.GetActorForwardVector());
			const float DistToBoat = DeltaToBoat.Size();
			DistanceToBoat = DistToBoat/StartDistanceToBoat;
			FMath::Clamp(DistanceToBoat, 0.0f, 1.0f);
			const float MoveAmount = FMath::Lerp(MoveSpeed.Min, MoveSpeed.Max, SpeedAlpha) * DeltaTime;
			const FVector DeltaMove = DeltaToBoat.GetSafeNormal() * FMath::Min(MoveAmount, DistToBoat);
			SetActorLocationAndRotation(GetActorLocation() + DeltaMove, DeltaToBoat.Rotation());
		}
		else
		{
			SetActorRotation(DeltaToBoat.Rotation());
		}

		//Flash Baby!!
	}

	void ActivateArm() override
	{
		bExploding = false;
		Super::ActivateArm();
		FollowBoatComponent.bFollowBoat = false;
		FollowBoatComponent.bFaceBoat = false;
	}

	void AnticipationAnimation() override
	{
		// Dont call super
		CannonBallDamageableComponent.EnableDamageTaking();
		// OctoArm.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), MHAnim);
	}

	void StartMoving()
	{
		bAttacking = true;

		AWheelBoatActor Boat = Cast<AWheelBoatActor>(PlayerTarget);
		StartDistanceToBoat = (Boat.BoatMesh.GetWorldLocation() - GetActorLocation()).Size();

		//PrintScaled("DuckEmerge", 1.f, FLinearColor::Red, 3.f);
		DuckEmergeEventInstance = HazeAkComp.HazePostEvent(DuckEmergeEvent);
	}

	bool IsMoving() const
	{
		return bAttacking;
	}

	void HitByCannonBall() override
	{
		// Dont call super
		if(ExplodeEffect != nullptr)
		{
			auto NiagaraComponent = Niagara::SpawnSystemAtLocation(ExplodeEffect, GetActorLocation(), GetActorRotation());
			NiagaraComponent.SetTranslucentSortPriority(3);
		}

		bExploding = true;

		//PrintScaled("DuckExplode", 1.f, FLinearColor::Red, 3.f);
		HazeAkComp.HazePostEvent(DuckExplodeEvent);
		HazeAkComp.HazePostEvent(ExplosionEvent);
		FinishAttack();
	}

	bool CanApplyDamage()const override
	{
		return bAttacking;
	}

	void OnArmEffectTriggered() override
	{
		if(ExplodeEffect != nullptr)
		{
			auto NiagaraComponent = Niagara::SpawnSystemAtLocation(ExplodeEffect, GetActorLocation(), GetActorRotation());
			NiagaraComponent.SetTranslucentSortPriority(3);
		}

		// Super::OnArmEffectTriggered();

		//PrintScaled("DuckExplode", 1.f, FLinearColor::Red, 3.f);
		HazeAkComp.HazePostEvent(DuckExplodeEvent);
		HazeAkComp.HazePostEvent(ExplosionEvent);

		if (CanApplyDamage())
		{
			PlayerTarget.BoatWasHit(DamageAmount, EWheelBoatHitType::CannonBall);

			Boss.ArmAttackHitPlayer(this);

			if(PirateOctopusSlamHitPlayerEvent != nullptr)
			{
				HazeAkComp.HazePostEvent(PirateOctopusSlamHitPlayerEvent);
			}
		}

		bExploding = true;
		FinishAttack();
	}

	void FinishAttack() override
	{
		Super::FinishAttack();

		if (SecondSequenceComp != nullptr)
		{
			SecondSequenceComp.RemoveArmFromPoint(this);
			SecondSequenceComp.bArmDied = true;
		}

		if(HazeAkComp.EventInstanceIsPlaying(DuckEmergeEventInstance))
			HazeAkComp.HazeStopEvent(DuckEmergeEventInstance.PlayingID);
	}
}


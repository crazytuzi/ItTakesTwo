import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.Environment.BreakableComponent;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

class ACastleSpinningBlade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBreakableComponent BreakableComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	USphereComponent DamageSphere;
	default DamageSphere.SphereRadius = 150.f;
	default DamageSphere.CollisionProfileName = n"OverlapAllDynamic";

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 3500.f;

	UPROPERTY()
	AHazeActor SplineActorToFollow;

	UPROPERTY(NotEditable)
	UHazeSplineComponent Spline;

	UPROPERTY()
	float DamageAmount = 15.f;
	UPROPERTY()
	float DamageCooldown = 0.2f;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	TPerPlayer<float> PlayerDamageCooldown;
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UPROPERTY()
	float MovementSpeed = 300.f;
	UPROPERTY()
	float RotationRate = 360.f;
	UPROPERTY()
	float DistanceAlongSpline;
	UPROPERTY()
	bool bMoveForwards = true;

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BreakableComponent.ConstructionScript_Hack();
		
		if (SplineActorToFollow == nullptr)
			return;

		if (Spline == nullptr)
			Spline = UHazeSplineComponent::Get(SplineActorToFollow);

		if (Spline == nullptr)
			return;

		SnapSpinningBladeToSpline();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActorToFollow == nullptr)
			return;
			
		Spline = UHazeSplineComponent::Get(SplineActorToFollow);		
	}
	    
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter PlayerCharacter = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (PlayerCharacter == nullptr)
			return;

		OverlappingPlayers.Add(PlayerCharacter);
		SpinningBladeDamagePlayer(PlayerCharacter);
    }

	UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter PlayerCharacter = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (PlayerCharacter == nullptr)
			return;

		OverlappingPlayers.Remove(PlayerCharacter);
		PlayerDamageCooldown[PlayerCharacter] = 0.f;
    }

	void SpinningBladeDamagePlayer(AHazePlayerCharacter Player)
	{
		if (!CanPlayerBeDamaged(Player))
			return;

		FCastlePlayerDamageEvent Damage;
		Damage.DamageDealt = DamageAmount;
		Damage.DamageLocation = Player.ActorLocation + FVector(0.f, 0.f, 100.f);

		FVector Direction = (Player.ActorLocation - ActorLocation).GetSafeNormal();
		Direction = Direction.RotateAngleAxis(FMath::RandRange(-20.f, 20.f), FVector::UpVector);
		Damage.DamageDirection = Direction;
		Damage.DamageSpeed = 900.f;

		PlayerDamageCooldown[Player] = DamageCooldown;

		DamageCastlePlayer(Player, Damage);
		Player.PlayForceFeedback(ForceFeedback, false, false, n"SpinningBladeDamage");

		FVector KnockImpulse = Direction.GetSafeNormal() * 300.f;
		Player.KnockdownActor(KnockImpulse);
	}

	void SnapSpinningBladeToSpline()
	{
		DistanceAlongSpline = Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);

		FVector BladeLocation = GetLocationAtDistanceAlongSpline(DistanceAlongSpline);

		SetActorLocation(BladeLocation);
	}

	FVector GetLocationAtDistanceAlongSpline(float DistanceAlongSpline)
	{
		FVector WorldLocation = Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		return WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Spline == nullptr)
			return;

		if (BreakableComponent.Broken)
			return;

		MoveBladeAlongSpline(DeltaTime);
		RotateBlade(DeltaTime);
		DamageOverlappingPlayers(DeltaTime);
	}

	void DamageOverlappingPlayers(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : OverlappingPlayers)
		{
			PlayerDamageCooldown[Player] -= DeltaTime;
			
			if (PlayerDamageCooldown[Player] <= 0.f)
			{
				SpinningBladeDamagePlayer(Player);
			}
				
		}

		/*for(float& Cooldown : PlayerDamageCooldown)
			Cooldown = 0.f;*/
	}

	void MoveBladeAlongSpline(float DeltaTime)
	{
		float UpdatedDistanceAlongSpline;

		float Direction;
		Direction = bMoveForwards ? 1.f  : -1.f;

		UpdatedDistanceAlongSpline = DistanceAlongSpline + (MovementSpeed * Direction * DeltaTime);

		if (bMoveForwards)
		{	
			if (UpdatedDistanceAlongSpline > Spline.GetSplineLength())
			{	
				UpdatedDistanceAlongSpline = Spline.GetSplineLength() - (UpdatedDistanceAlongSpline - Spline.GetSplineLength());
				bMoveForwards = false;
			}
		}
		else
		{
			if (UpdatedDistanceAlongSpline < 0.f)
			{
				UpdatedDistanceAlongSpline *= -1.f;
				bMoveForwards = true;
			}
		}

		DistanceAlongSpline = UpdatedDistanceAlongSpline;

		SetActorLocation(Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World));
	}

	void RotateBlade(float DeltaTime)
	{
		FRotator NewSawRotation = Root.WorldRotation;		
		NewSawRotation.Yaw += RotationRate * DeltaTime;
	
		Root.SetWorldRotation(FQuat(NewSawRotation));
	}
}
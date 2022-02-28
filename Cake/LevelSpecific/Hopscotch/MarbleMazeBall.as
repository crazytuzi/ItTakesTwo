import Vino.Movement.Components.MovementComponent;

//audio marble ball velocity rtpc to add : Rtpc_Gadget_MarbleBall_Maze_Velocity

event void FMarbleBallReachedGoal();

class AMarbleMazeBall : AHazeActor
{	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	
	UPROPERTY(DefaultComponent, Attach = CapsuleComp)
	UStaticMeshComponent BallMesh;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMarbleMazeBallAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMarbleMazeBallAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactMarbleMazeBallAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FailMarbleMazeBallAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SuccessMarbleMazeBallAudioEvent;

	UPROPERTY()
	FMarbleBallReachedGoal MarbleBallReachedGoal;

	FVector TargetLocation;
	FVector CurrentLocation;

	FVector TargetLinearVelocity;
	FVector TargetAngularVelocity;

	FVector CurrentLinearVelocity;
	FVector CurrentAngularVelocity;

	FVector LocationLastTick = FVector::ZeroVector;
	FVector CurrentGoalLoc = FVector::ZeroVector;

	FRotator MazeRotation;

	bool bShouldLerpToGoal = false;

	bool bBallActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(CapsuleComp);
		HazeAkComp.HazePostEvent(StartMarbleMazeBallAudioEvent);
	}

	UFUNCTION()
	void SetBallActive(bool bActive)
	{
		EHazeActionState State = bActive ? EHazeActionState::Active : EHazeActionState::Inactive;
		SetCapabilityActionState(n"MazeBallActive", State);
	}

	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		HazeAkComp.HazePostEvent(StopMarbleMazeBallAudioEvent);
	}

	void AddBallCapability()
	{
		AddCapability(n"MarbleMazeBallCapability");
	}

	void GetMazeRotation(FRotator Rotation)
	{
		MazeRotation = Rotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		CurrentDelta(DeltaTime);
		RotateBallMesh(DeltaTime);	
	}

	void BallFellOut()
	{

	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSyncBall(FVector NewTargetLocation)
	{
		TargetLocation =  NewTargetLocation;
	}

	void BallReachedGoal()
	{
		HazeAkComp.HazePostEvent(SuccessMarbleMazeBallAudioEvent);
	}

	void BallFailed()
	{
		HazeAkComp.HazePostEvent(FailMarbleMazeBallAudioEvent);
		//PrintToScreenScaled("ball failed", 2.f, FLinearColor :: LucBlue, 2.f);
	}

	void OnBallHitWall()
	{	
		HazeAkComp.HazePostEvent(ImpactMarbleMazeBallAudioEvent);	
	}

	float CurrentDelta(float DeltaTime)
	{
		float Delta = (GetActorLocation() - LocationLastTick).Size();
		Delta = (Delta * 90.f) * DeltaTime;
		float DeltaMapped = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 20.f), FVector2D(0.f, 1.f), Delta);
		LocationLastTick = GetActorLocation();	
		if (!MoveComp.IsGrounded())	
			DeltaMapped = 0.f;
		
		HazeAkComp.SetRTPCValue("Rtpc_Gadget_MarbleBall_Maze_Velocity", DeltaMapped);

		return DeltaMapped;
	}

	void RotateBallMesh(float DeltaTime)
	{
		FVector PlaneVelo = FVector(MoveComp.ActualVelocity.X, MoveComp.ActualVelocity.Y, 0.f);
		FVector Cross = FVector::UpVector.CrossProduct(PlaneVelo);
		FRotator BallDirectionRotation = FMath::RotatorFromAxisAndAngle(Cross, PlaneVelo.Size() * DeltaTime);
		FRotator FinalRotation = BallMesh.WorldRotation.Compose(BallDirectionRotation);
		BallMesh.SetWorldRotation(FinalRotation);
	}
}
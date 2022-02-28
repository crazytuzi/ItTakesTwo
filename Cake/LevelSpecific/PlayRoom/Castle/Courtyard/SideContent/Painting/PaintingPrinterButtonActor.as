import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

event void FPaintingPrinterButtonGroundPoundedEventSignature(AHazePlayerCharacter Player);

//Add reset from callback of printing new paper/posting painting to podium

class APaintingPrinterButtonActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ButtonFrameMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonRoot;
	default ButtonRoot.RelativeLocation = FVector(0,0,10);

	UPROPERTY(DefaultComponent, Attach = ButtonRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent, Attach = ButtonMesh)
	USphereComponent OverlapTrigger;

	UPROPERTY(DefaultComponent, Attach = ButtonMash)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonPushAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonResetAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwayEnterAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwayExitAudioEvent;

	UPROPERTY()
	FPaintingPrinterButtonGroundPoundedEventSignature OnGroundPounded;

	AHazePlayerCharacter PoundingPlayer;
	FHazeConstrainedPhysicsValue PhysicsValue;

	bool bShouldUpdateSpring = true;
	bool IsPressed = false;
	bool bIsGroundPounded = false;
	bool bMessagedGroundPound = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PhysicsValue.LowerBound = -35.f;
		PhysicsValue.UpperBound = 0;
		PhysicsValue.LowerBounciness = 0.1f;
		PhysicsValue.UpperBounciness = 0.3f;
		PhysicsValue.Friction = 1.5f;

		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ButtonGroundPounded");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldUpdateSpring)
			CalcDownForce(DeltaTime);
		if(bIsGroundPounded)
			UpdateGroundPoundProgress(DeltaTime);
	}

	UFUNCTION()
	void ButtonGroundPounded(AHazePlayerCharacter Player)
	{
		if(bShouldUpdateSpring)
		{
			bShouldUpdateSpring = false;
			bIsGroundPounded = true;
			PoundingPlayer = Player;
			
			AkComp.HazePostEvent(ButtonPushAudioEvent);
		}
	}

	UFUNCTION()
	void ResetButton()
	{
		PhysicsValue.SnapTo(ButtonMesh.RelativeLocation.Z, true);
		bShouldUpdateSpring = true;
		bIsGroundPounded = false;
		PoundingPlayer = nullptr;
		bMessagedGroundPound = false;

		AkComp.HazePostEvent(ButtonResetAudioEvent);
	}

	void CalcDownForce(float DeltaTime)
	{
		PhysicsValue.SpringTowards(0, 100.f);

		if(IsPressed)
			PhysicsValue.AddAcceleration(-800.f);

		PhysicsValue.Update(DeltaTime);
		FVector MeshLocation = ButtonMesh.RelativeLocation;
		MeshLocation.Z = PhysicsValue.Value;
		ButtonMesh.RelativeLocation = MeshLocation;
	}

	UFUNCTION()
	void UpdateGroundPoundProgress(float DeltaTime)
	{
		FVector DesiredRelativeLocation = FVector::ZeroVector;
		DesiredRelativeLocation.Z = -35.f;
		ButtonMesh.RelativeLocation = FMath::Lerp(ButtonMesh.RelativeLocation, DesiredRelativeLocation, FMath::Clamp(DeltaTime * 20.f, 0.f, 1.f));

		if(ButtonMesh.RelativeLocation.Z < 0.01f && !bMessagedGroundPound)
		{
			OnGroundPounded.Broadcast(PoundingPlayer);
			bMessagedGroundPound = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if(!OtherActor.IsA(AHazePlayerCharacter::StaticClass()))
			return;

		if(!IsPressed)
		{
			IsPressed = true;
			UHazeAkComponent::HazePostEventFireForget(SwayEnterAudioEvent, this.GetActorTransform());	
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if(!OtherActor.IsA(AHazePlayerCharacter::StaticClass()))
			return;
		
		if(IsPressed)
		{
			IsPressed = false;
			UHazeAkComponent::HazePostEventFireForget(SwayExitAudioEvent, this.GetActorTransform());	
		}
	}
}
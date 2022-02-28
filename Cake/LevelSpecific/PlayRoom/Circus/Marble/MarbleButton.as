import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

event void FMarblebuttonGroundpoundedEventSignature(AHazePlayerCharacter Player);
class AMarbleButton : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Collision;

    UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonGroundpoundedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonResetAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonSwayAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonLeaveAudioEvent;

	AHazePlayerCharacter PoundingPlayer;

	FHazeConstrainedPhysicsValue PhysicsValue;

	float TimeUntilReset;

	UPROPERTY()
	bool IsPressed;
	
	UPROPERTY()
	FMarblebuttonGroundpoundedEventSignature OnGroundPounded;

	UPROPERTY()
	float TimeSpentStanding = 0;

	bool bShouldUpdateSpring = true;
	bool bIsGroundPounded = false;
	bool bMessagedGroundPound = false;

	UPROPERTY()
	bool bStartDisabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ButtonGroundPounded");
		PhysicsValue.LowerBound = -30;
		PhysicsValue.UpperBound = 0;
		PhysicsValue.LowerBounciness = 0;
		PhysicsValue.UpperBounciness = 1.f;
		PhysicsValue.Friction = 6.5f;

		if (bStartDisabled)
		{
			bShouldUpdateSpring = false;
			SnapToBottomPosition();
		}
	}

    UFUNCTION(NotBlueprintCallable)
    void ButtonGroundPounded(AHazePlayerCharacter Player)
    {
		if (bShouldUpdateSpring)
		{
			bShouldUpdateSpring = false;
			bIsGroundPounded = true;
			bMessagedGroundPound = false;
			PoundingPlayer = Player;

			Player.PlayerHazeAkComp.HazePostEvent(ButtonGroundpoundedAudioEvent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
    {
		if(!OtherActor.IsA(AHazePlayerCharacter::StaticClass()))
			return;

		if (!IsPressed)
		{
			if(!bIsGroundPounded && bShouldUpdateSpring)
				UHazeAkComponent::HazePostEventFireForget(ButtonSwayAudioEvent, this.GetActorTransform());
			IsPressed = true;
			PlayButtonEffects(Cast<AHazePlayerCharacter>(OtherActor));
			TimeSpentStanding = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if(!OtherActor.IsA(AHazePlayerCharacter::StaticClass()))
			return;

		if (IsPressed)
		{
			if(!bIsGroundPounded && bShouldUpdateSpring)
				UHazeAkComponent::HazePostEventFireForget(ButtonLeaveAudioEvent, this.GetActorTransform());
			
			IsPressed = false;
			LeftButton();
		}
	}

	UFUNCTION(BlueprintEvent)
	void LeftButton()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void PlayButtonEffects(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldUpdateSpring)
		{
			CalcDownForce(DeltaTime);
		}
		else if (bIsGroundPounded)
		{
			UpdateGroundPoundProgress(DeltaTime);
		}
	}

	UFUNCTION()
	void UpdateGroundPoundProgress(float DeltaTime)
	{
		FVector DesiredRelativeLocation = FVector::ZeroVector;
		DesiredRelativeLocation.Z = -85.f;
		Mesh.RelativeLocation = FMath::Lerp(Mesh.RelativeLocation, DesiredRelativeLocation, FMath::Clamp(DeltaTime * 20.f, 0.f, 1.f));

		if (Mesh.RelativeLocation.Z < 0.01f && !bMessagedGroundPound)
		{
			OnGroundPounded.Broadcast(PoundingPlayer);
			bMessagedGroundPound = true;
		}
	}

	float GetFractionPushedDown()
	{
		float Min = 85;
		float Max = 0;
		float Position = Mesh.RelativeLocation.Z;

		return FMath::Abs(Position) / Min;
	}

	void CalcDownForce(float DeltaTime)
	{
		PhysicsValue.SpringTowards(0.f, 150.f);
		if(IsPressed)
		{
			PhysicsValue.AddAcceleration(-2000.f);
		}

		PhysicsValue.Update(DeltaTime);
		FVector MeshLocation = Mesh.RelativeLocation;
		MeshLocation.Z = PhysicsValue.Value;
		Mesh.RelativeLocation = MeshLocation;
	}


	void SnapToBottomPosition()
	{
		FVector MeshLocation = Mesh.RelativeLocation;
		MeshLocation.Z = -85;
		Mesh.RelativeLocation = MeshLocation;
	}

	UFUNCTION(NetFunction)
	void ActivateButton()
	{
		if (HasControl())
		{
			NetActivatebutton();
		}
	}

	UFUNCTION(NetFunction)
	void NetActivatebutton()
	{
		UHazeAkComponent::HazePostEventFireForget(ButtonResetAudioEvent, this.GetActorTransform());
		bShouldUpdateSpring = true;
		bIsGroundPounded = false;
		TimeSpentStanding = 0;
		PhysicsValue.Value = -85;
		PhysicsValue.LowerBound = -85;
	}
}
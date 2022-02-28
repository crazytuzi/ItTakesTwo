import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;


class ATugOfWarShower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PoITarget;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ShowerMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonRoot;
	default ButtonRoot.SetRelativeLocation(FVector(292.5f,0,0));

	UPROPERTY(DefaultComponent, Attach = ButtonRoot)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent, Attach = ButtonRoot)
	UCapsuleComponent Collision;
	default Collision.CapsuleHalfHeight  = 110;
	default Collision.CapsuleRadius = 110;
	default Collision.SetRelativeLocation(FVector(0,0,70.f));

	AHazePlayerCharacter PoundingPlayer;

	FHazeConstrainedPhysicsValue PhysicsValue;

	UPROPERTY(EditInstanceOnly)
	ATugOfWarShower LinkedShowerActor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ShowerEffect;

	AHazePlayerCharacter OverlappingPlayer;

	UPROPERTY()
	bool IsPressed;

	bool bShouldUpdateSpring = true;
	bool bShowerActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PhysicsValue.LowerBound = -70.f;
		PhysicsValue.UpperBound = 0;
		PhysicsValue.LowerBounciness = 0;
		PhysicsValue.UpperBounciness = 1.f;
		PhysicsValue.Friction = 6.5f;
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if(!OtherActor.IsA(AHazePlayerCharacter::StaticClass()))
			return;
		else
		{
			OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
			FHazePointOfInterest PoI;
			PoI.FocusTarget.Component = LinkedShowerActor.PoITarget;
			PoI.Blend.BlendTime = 1.f;
			OverlappingPlayer.ApplyPointOfInterest(PoI, this);
		}

		
		if(!IsPressed)
		{
			IsPressed = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if(!OtherActor.IsA(AHazePlayerCharacter::StaticClass()))
			return;
		else
		{
			OverlappingPlayer.ClearPointOfInterestByInstigator(this);
			OverlappingPlayer = nullptr;
		}
		
		if(IsPressed)
		{
			IsPressed = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldUpdateSpring)
			CalcDownForce(DeltaTime);
		
		if(IsPressed && ButtonMesh.RelativeLocation.Z < -50.f && !LinkedShowerActor.bShowerActivated)
			LinkedShowerActor.ActivateShower();
		else if(!IsPressed && LinkedShowerActor.bShowerActivated)
			LinkedShowerActor.DeactivateShower();
	}

	void CalcDownForce(float DeltaTime)
	{
		PhysicsValue.SpringTowards(0, 75.f);

		if(IsPressed)
			PhysicsValue.AddAcceleration(-4000.f);
		
		PhysicsValue.Update(DeltaTime);
		FVector MeshLocation = ButtonMesh.RelativeLocation;
		MeshLocation.Z = PhysicsValue.Value;
		ButtonMesh.RelativeLocation = MeshLocation;
	}


	UFUNCTION()
	void UpdateGroundPoundProgress(float DeltaTime)
	{
		FVector DesiredRelativeLocation = FVector::ZeroVector;
		DesiredRelativeLocation.Z = -70.f;
		ButtonMesh.RelativeLocation = FMath::Lerp(ButtonMesh.RelativeLocation, DesiredRelativeLocation, FMath::Clamp(DeltaTime * 20.f, 0.f, 1.f));
	}

	//Called by LinkedShowerActor
	void ActivateShower()
	{
		bShowerActivated = true;
		ShowerEffect.Activate();
	}
	//Called by LinkedShowerActor
	void DeactivateShower()
	{
		bShowerActivated = false;
		ShowerEffect.Deactivate();
	}
}
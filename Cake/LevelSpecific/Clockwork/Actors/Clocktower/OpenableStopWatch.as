import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.BouncePad.BouncePadResponseComponent;

class OpenableStopWatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent JumpToLoc;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent StopWatchBack;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent StopWatchLid;

	UPROPERTY(DefaultComponent, Attach = StopWatchLid)
	UStaticMeshComponent PhysicsRoot;

	UPROPERTY(DefaultComponent, Attach = PhysicsRoot)
	UStaticMeshComponent BumperSpring;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent DeathTrigerBox;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OpenEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CloseEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LandEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GroundPoundEvent;

	UPROPERTY()
	bool LaunchOnLanded = false;

	UPROPERTY()
	bool OpenOnBeginPlay = false;

	UPROPERTY()
	float AddedHeight = 1500.f;
	
	UPROPERTY()
	bool bIsBouncePad = true;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BounceEffect;

	UPROPERTY(EditDefaultsOnly)
    TSubclassOf<UHazeCapability> BouncePadCapabilityClass;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -75.f;
	default PhysValue.UpperBound = 150.f;
	default PhysValue.LowerBounciness = 1.f;
	default PhysValue.UpperBounciness = 0.65f;
	default PhysValue.Friction = 1.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		BouncePadComp.OnBounce.AddUFunction(this, n"Bounced");

		if (bIsBouncePad)
			Capability::AddPlayerCapabilityRequest(BouncePadCapabilityClass);
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
		if (bIsBouncePad)
        	Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityClass);
    }

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if(Hit.Component != BumperSpring)
			return;

		if (!bIsBouncePad)
		{
			PhysValue.AddImpulse(-1500.f);
			FHazeJumpToData JumpToData;
			JumpToData.TargetComponent = JumpToLoc;
			JumpToData.AdditionalHeight = AddedHeight;
			BP_LaunchPlayer(JumpToData, Player);
			HazeAkComp.HazePostEvent(GroundPoundEvent);
		}
		else
		{
			Player.SetCapabilityAttributeValue(n"VerticalVelocity", 2300.f);
			Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", 0.65f);
			Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchPlayer(FHazeJumpToData JumpData, AHazePlayerCharacter Player) {}

	UFUNCTION(NotBlueprintCallable)
	void Bounced(AHazePlayerCharacter Player, bool bGroundPounded)
	{
		PhysValue.AddImpulse(-1500.f);
		Niagara::SpawnSystemAtLocation(BounceEffect, Player.ActorLocation);
		Player.PlayerHazeAkComp.HazePostEvent(GroundPoundEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 35.f);
		PhysValue.Update(DeltaTime);

		PhysicsRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));
	}
}
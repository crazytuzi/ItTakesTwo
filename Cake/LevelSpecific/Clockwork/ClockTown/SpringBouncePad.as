import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.BouncePad.BouncePadResponseComponent;

UCLASS(Abstract)
class ASpringBouncePad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpringRoot;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	UStaticMeshComponent SpringMesh;

	UPROPERTY(DefaultComponent, Attach = SpringRoot)
	UStaticMeshComponent BoardMesh;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BounceComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceEvent;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> BounceCapability;

	UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1650.f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 600.f;

	UPROPERTY(Category = "Effects", EditDefaultsOnly)
	UNiagaraSystem BounceEffect;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = 90.f;
	default PhysValue.UpperBound = 150.f;
	default PhysValue.LowerBounciness = 0.9f;
	default PhysValue.UpperBounciness = 0.4f;
	default PhysValue.Friction = 1.8f;

	float PrevSpringValue = 150.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SpringMesh.SetCullDistance(Editor::GetDefaultCullingDistance(SpringMesh) * CullDistanceMultiplier);
		BoardMesh.SetCullDistance(Editor::GetDefaultCullingDistance(BoardMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(BounceCapability);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		BounceComp.OnBounce.AddUFunction(this, n"TriggerSpringEffect");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(BounceCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		LaunchPlayer(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerSpringEffect(AHazePlayerCharacter Player, bool bGroundPounded)
	{
		Niagara::SpawnSystemAtLocation(BounceEffect, Player.ActorLocation);
		PhysValue.AddImpulse(-1600.f);
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(150.f, 350.f);
		PhysValue.Update(DeltaTime);

		if (PrevSpringValue != PhysValue.Value)
		{
			SpringRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));
			PrevSpringValue = PhysValue.Value;
		}
		else
			SetActorTickEnabled(false);
	}

	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
		UHazeAkComponent::HazePostEventFireForget(BounceEvent, GetActorTransform());
	}
}
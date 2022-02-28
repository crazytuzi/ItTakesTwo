import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

UCLASS(Abstract)
class AClockTownBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PhysicsRoot;

	UPROPERTY(DefaultComponent, Attach = PhysicsRoot)
	USceneComponent BoatRoot;

	UPROPERTY(DefaultComponent, Attach = BoatRoot)
	UStaticMeshComponent BoatMesh;

	UPROPERTY(DefaultComponent, Attach = BoatRoot)
	UHazeSkeletalMeshComponentBase CharacterSkelMesh;

	UPROPERTY(DefaultComponent, Attach = CharacterSkelMesh, AttachSocket = RightAttach)
	UHazeSkeletalMeshComponentBase FishingRodMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 11000;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LandAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpAudioEvent;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -50.f;
	default PhysValue.UpperBound = 0.f;
	default PhysValue.LowerBounciness = 0.5f;
	default PhysValue.UpperBounciness = 0.65f;
	default PhysValue.Friction = 0.5f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BoatMesh.SetCullDistance(Editor::GetDefaultCullingDistance(BoatMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnBoat");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeaveBoat");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnBoat(AHazePlayerCharacter Player, FHitResult Hit)
	{
		PhysValue.AddImpulse(-370.f);
		UHazeAkComponent::HazePostEventFireForget(LandAudioEvent, GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void LeaveBoat(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(-100.f);
		UHazeAkComponent::HazePostEventFireForget(JumpAudioEvent, GetActorTransform());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 35.f);
		PhysValue.Update(DeltaTime);

		PhysicsRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));
	}
}
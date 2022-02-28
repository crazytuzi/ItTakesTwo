import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
import Vino.BouncePad.BouncePadResponseComponent;

event void FOnBouncePadBouncedOn(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ABouncePad : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;
	default RootComp.Mobility = EComponentMobility::Static;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent BouncePadMesh;
    default BouncePadMesh.StaticMesh = Asset("/Game/Environment/Props/Fantasy/PlayRoom/Pillowfort/Pillow_01.Pillow_01");
	default BouncePadMesh.Mobility = EComponentMobility::Movable;
	default BouncePadMesh.LightmapType = ELightmapType::ForceSurface;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent VerticalBounceDirection;
    default VerticalBounceDirection.RelativeRotation = FRotator(90.f, 0.f, 0.f);
    default VerticalBounceDirection.ArrowSize = 3.f;
    default VerticalBounceDirection.RelativeLocation = FVector(0.f, 0.f, 100.f);
    default VerticalBounceDirection.bVisible = false;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadComp;

	UPROPERTY(DefaultComponent)
    UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 5000;
	default DisableComponent.bRenderWhileDisabled = true;

    UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
    TSubclassOf<UHazeCapability> BouncePadCapabilityClass;

    UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1500.f;

	UPROPERTY(Category = "Bounce Properties")
	float GroundPoundHeightModifier = 1.25f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;

    UPROPERTY(Category = "Bounce Properties")
    bool bCustomVerticalDirection = false;

	UPROPERTY(Category = "Mesh")
	UStaticMesh MeshOverride;

    UPROPERTY(Category = "Mesh")
    FVector EndScale = FVector(1.1f, 1.1f, 0.75f);

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

    UPROPERTY(Category = "Mesh")
    FHazeTimeLike ScaleBouncePadTimeLike;
    default ScaleBouncePadTimeLike.Duration = 0.2f;
    default ScaleBouncePadTimeLike.Curve.ExternalCurve = Asset("/Game/Blueprints/LevelMechanics/BouncePad/BouncePadScaleCurve.BouncePadScaleCurve");

	// If only one specific component should trigger an impact and bounce the actor
	UPROPERTY(Category = "Mesh")
	bool bSpecificImpactComponent = false;

	// Name of the component that can trigger an impact
	UPROPERTY(Category = "Mesh", Meta = (EditCondition = "bSpecificImpactComponent"))
	FString ComponentToBeImpacted;

    UPROPERTY(Category = "Mesh")
    float ScalePlayRate = 1.f;

	UPROPERTY(Category = "Effects")
	UNiagaraSystem BounceEffect = Asset("/Game/Effects/Niagara/GameplayBouncePad_01.GameplayBouncePad_01");

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceEvent;

    FVector StartScale = FVector::OneVector;

    UPROPERTY()
    FOnBouncePadBouncedOn OnBouncePadBouncedOn;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        VerticalBounceDirection.SetVisibility(bCustomVerticalDirection);

		if (MeshOverride != nullptr)
		{
			BouncePadMesh.SetStaticMesh(MeshOverride);
			BouncePadMesh.SetCustomPrimitiveDataFloat(0, FMath::FRand());
		}
		
		BouncePadMesh.SetCullDistance(Editor::GetDefaultCullingDistance(BouncePadMesh) * CullDistanceMultiplier);
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnBouncePad");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);
		UActorImpactedCallbackComponent::Get(this).bCanBeActivedLocallyOnTheRemote = true;
		
        ScaleBouncePadTimeLike.BindUpdate(this, n"UpdateScaleBouncePad");
        ScaleBouncePadTimeLike.BindFinished(this, n"FinishScaleBouncePad");

        ScaleBouncePadTimeLike.SetPlayRate(ScalePlayRate);

        Capability::AddPlayerCapabilityRequest(BouncePadCapabilityClass);

		BouncePadComp.OnBounce.AddUFunction(this, n"Bounced");
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityClass);
    }

    UFUNCTION()
    void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult)
    {
        if (Player.HasControl())
        {
			if (bSpecificImpactComponent)
			{
				if (HitResult.Component.Name != ComponentToBeImpacted)
					return;
			}

			bool bGroundPounded = false;
			if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
				bGroundPounded = true;

			if (bCustomVerticalDirection)
				Player.SetCapabilityAttributeVector(n"VerticalVelocityDirection", VerticalBounceDirection.ForwardVector);

			if (GroundPoundHeightModifier != 1.25f)
				Player.SetCapabilityAttributeValue(n"GroundPoundModifier", GroundPoundHeightModifier);
			
			Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
			Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
			Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
        }
    }

	UFUNCTION(NotBlueprintCallable)
	void Bounced(AHazePlayerCharacter Player, bool bGroundPounded)
	{
		Niagara::SpawnSystemAtLocation(BounceEffect, Player.ActorLocation);

		TriggerSquishEffect();
		OnBouncePadBouncedOn.Broadcast(Player);
		if (bGroundPounded)
		{
			BP_GroundPounded();
			Player.PlayerHazeAkComp.HazePostEvent(BounceEvent);
		}
			
		else
		{
			BP_Bounced();
			Player.PlayerHazeAkComp.HazePostEvent(BounceEvent);
		}
			
	}

	void TriggerSquishEffect()
	{
		ScaleBouncePadTimeLike.PlayFromStart();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Bounced() {}

	UFUNCTION(BlueprintEvent)
	void BP_GroundPounded() {}

    UFUNCTION()
    void UpdateScaleBouncePad(float CurValue)
    {
        FVector CurScale = FMath::Lerp(StartScale, EndScale, CurValue);
        BouncePadMesh.SetRelativeScale3D(CurScale);
    }

    UFUNCTION()
    void FinishScaleBouncePad()
    {

    }
}

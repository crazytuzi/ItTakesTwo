import Vino.Movement.Swinging.SwingComponent;

UCLASS(Abstract)
class ASwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;	

	UPROPERTY(DefaultComponent, Attach = Billboard, ShowOnActor)
	USwingPointComponent SwingPointComponent;

	UPROPERTY(DefaultComponent, Attach = SwingPointComponent)
	UHazeStaticMeshComponent StaticMesh;
	default StaticMesh.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Visible) * 2.f;
	default DisableComponent.bActorIsVisualOnly = true;
	default DisableComponent.bRenderWhileDisabled = true;

	//audio events to trigger custom sounds on special swing points
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnAttachAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnDetachAudioEvent;
	
	UPROPERTY(DefaultComponent, Attach = SwingPointComponent)
	USphereComponent SelectableDistance;
	default SelectableDistance.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default SelectableDistance.bIsEditorOnly = true;
	default SelectableDistance.SphereRadius = SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Selectable);
	default SelectableDistance.bGenerateOverlapEvents = false;
	
	UPROPERTY()
	FOnSwingPointAttached OnSwingPointAttached;
	UPROPERTY()
	FOnSwingPointDetached OnSwingPointDetached;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		StaticMesh.SetCullDistance(Editor::GetDefaultCullingDistance(StaticMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPointComponent.OnSwingPointAttached.AddUFunction(this, n"SwingPointAttached");
		SwingPointComponent.OnSwingPointDetached.AddUFunction(this, n"SwingPointDetached");

		// Safety if the swingpoints setup has been messed up
		const float SelectedableDistance = SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Visible);
		if(DisableComponent.AutoDisableRange < SelectedableDistance)
			DisableComponent.AutoDisableRange = SelectedableDistance;
	}

	UFUNCTION()
	void SwingPointAttached(AHazePlayerCharacter Player)
	{
		OnSwingPointAttached.Broadcast(Player);
		UHazeAkComponent::HazePostEventFireForget(OnAttachAudioEvent, SwingPointComponent.GetWorldTransform());
	}

	UFUNCTION()
	void SwingPointDetached(AHazePlayerCharacter Player)
	{
		OnSwingPointDetached.Broadcast(Player);
		UHazeAkComponent::HazePostEventFireForget(OnDetachAudioEvent, SwingPointComponent.GetWorldTransform());
	}

	UFUNCTION()
	void SetSwingPointEnabled(bool bEnabled = false)
	{
		SwingPointComponent.SetSwingPointEnabled(bEnabled);
	}
}

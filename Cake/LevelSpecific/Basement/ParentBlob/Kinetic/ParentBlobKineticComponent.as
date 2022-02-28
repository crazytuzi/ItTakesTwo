
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticWidget;

enum EKineticInputVisualizerStatus
{
	Inactive,
	ActiveWithNoTarget,
	ActiveWithNoTargetAndInput,
	ActiveWithTarget,
	ActiveWithTargetAndInput,
	ActiveWithTargetAndValidDirection,
	ActiveWithTargetAndInputAndValidDirection
}

UCLASS(Abstract)
class AKineticInputVisualizer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent LightComponent;

	UPROPERTY(DefaultComponent, Attach = Root, Category = "Effect")
	UNiagaraComponent EffectComponent;

	UPROPERTY(Category = "Effect")
	float ActiveTargetRadius = 5.f;

	UPROPERTY(Category = "Effect")
	float ActiveTargetSpawnRate = 2.f;

	UPROPERTY(Category = "Effect")
	float NoTargetRadius = 20.f;

	UPROPERTY(Category = "Effect")
	float NoTargetSpawnRate = 10.f;

	UPROPERTY(Category = "Effect")
	float LightRadiusMultiplier = 10.f;

	UPROPERTY(BlueprintReadOnly, EditConst)
	EKineticInputVisualizerStatus Status = EKineticInputVisualizerStatus::Inactive;

	float Radius;
	float TargetRadius;
	float SpawnRate;
	float TargetSpawnRate;

	float LightIntensity;
	float TargetLightIntensity;

	float ActiveLightIntensity = 1000.f;
	float InactiveLightIntensity = 500.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Radius = FMath::FInterpTo(Radius, TargetRadius, DeltaSeconds, 5.f);
		EffectComponent.SetFloatParameter(n"Radius", Radius);

		SpawnRate = FMath::FInterpTo(SpawnRate, TargetSpawnRate, DeltaSeconds, 5.f);
		EffectComponent.SetFloatParameter(n"SpawnRate", SpawnRate);
			
		// LightComponent.SetAttenuationRadius(Radius * LightRadiusMultiplier);
		
		LightIntensity = FMath::FInterpTo(LightIntensity, TargetLightIntensity, DeltaSeconds, 5.f);
		LightComponent.SetIntensity(LightIntensity);
	}

	void SetStatus(EKineticInputVisualizerStatus NewStatus)
	{
		if(NewStatus == Status)
			return;

		if(NewStatus == EKineticInputVisualizerStatus::Inactive)
		{
			TargetRadius = 0;
			TargetSpawnRate = 0;
			// DisableActor(nullptr);
			EffectComponent.Deactivate();
			TargetLightIntensity = 0.f;
		}
		else
		{
			if(Status == EKineticInputVisualizerStatus::Inactive)
			{
				EffectComponent.Activate(true);
				TargetLightIntensity = ActiveLightIntensity;
				// EnableActor(nullptr);
			}

			if(NewStatus == EKineticInputVisualizerStatus::ActiveWithNoTarget)
			{
				TargetRadius = NoTargetRadius;
				TargetSpawnRate = NoTargetSpawnRate;
				TargetLightIntensity = InactiveLightIntensity;
			}
			else if(NewStatus == EKineticInputVisualizerStatus::ActiveWithNoTargetAndInput)
			{
				TargetRadius = NoTargetRadius * 10;
				TargetSpawnRate = NoTargetSpawnRate;
				TargetLightIntensity = InactiveLightIntensity;
			}
			else if(NewStatus == EKineticInputVisualizerStatus::ActiveWithTarget)
			{
				TargetRadius = ActiveTargetRadius;
				TargetSpawnRate = ActiveTargetSpawnRate;
				TargetLightIntensity = ActiveLightIntensity;
			}
			else if(NewStatus == EKineticInputVisualizerStatus::ActiveWithTargetAndInput
				|| NewStatus == EKineticInputVisualizerStatus::ActiveWithTargetAndValidDirection
				|| NewStatus == EKineticInputVisualizerStatus::ActiveWithTargetAndInputAndValidDirection)
			{
				TargetRadius = ActiveTargetRadius;
				TargetSpawnRate = ActiveTargetSpawnRate;
				TargetLightIntensity = ActiveLightIntensity;
			}
		}

		Status = NewStatus;
	}
}

struct FParentBlobKineticInputSettingsData
{
	UPROPERTY()
	FName AttachBoneName;

	UPROPERTY()
	FVector AttachOffset;
		
	UPROPERTY()
	bool bUseClamps = false;

	UPROPERTY(meta = (EditCondition = "bUseClamps"))
	FHazeMinMax InputClamp;
}

struct FParentBlobKineticPlayerInputData
{
	// If true, we can steer the lightning balls towards the interaction
	private const bool bCanFreelyPickInteractionTarget = true;

	// The correct input offset required to count as valid input when we have an interaciton
	// Invalid if less then -1.f
	private const float InputAngleRequiredToBeValid = -0.5f;

	bool bIsHolding = false;
	bool bHasSteeringInput = false;
	bool bSteeringIsToFindInteraction = false;
	float InputAngle = 0;
	UParentBlobKineticInteractionComponent TargetedInteraction;

	const bool GetInputRequiredToActivateInteraction() const property
	{
		// return InputAngleRequiredToBeValid >= -1.f;
		return false;
	}

	const bool GetFreelyPickInteractionTarget() const property
	{
		return bCanFreelyPickInteractionTarget;
	}

	const bool GetInputIsValidToRequiredAngle() const property
	{
		if(InputAngle < InputAngleRequiredToBeValid)
			return false;
		
		return true;
	}
}

class UParentBlobKineticInputSettings : UDataAsset
{
	UPROPERTY()
	FRuntimeFloatCurve HeightOffsetInRelationToInputAngle;

	UPROPERTY()
	FRuntimeFloatCurve ForwardOffsetInRelationToInputAngle;

	UPROPERTY(meta = (ShowOnlyInnerProperties))
	FParentBlobKineticInputSettingsData MaySettings;

	UPROPERTY(meta = (ShowOnlyInnerProperties))
	FParentBlobKineticInputSettingsData CodySettings;
}

class UParentBlobKineticComponent : UActorComponent
{
	UPROPERTY(Category = "Widget")
	TSubclassOf<UParentBlobKineticWidget> WidgetClass;

	UPROPERTY(Category = "Visualize")
	TSubclassOf<AKineticInputVisualizer> KineticInputVisualizerClassCody;

	UPROPERTY(Category = "Visualize")
	TSubclassOf<AKineticInputVisualizer> KineticInputVisualizerClassMay;

	UPROPERTY(Category = "Input")
	UParentBlobKineticInputSettings DefaultInputSettings;

	UPROPERTY(Category = "Animation")
	UBlendSpace HoldBS;

	UPROPERTY(EditConst, Category = "Widget")
	UParentBlobKineticWidget HoldWidget;

	UPROPERTY(EditConst, Category = "Input")
	TPerPlayer<FParentBlobKineticPlayerInputData> PlayerInputData;
	
	UPROPERTY(EditConst, Category = "Input")
	TPerPlayer<AKineticInputVisualizer> KineticInputVisualizers;

	EParentBlobKineticInteractionStatus InteractionStatus = EParentBlobKineticInteractionStatus::OutOfReach;
	USkeletalMeshComponent OwnerMesh;
	bool bWidgetIsVisible = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// This component ticks through capabilites
		SetComponentTickEnabled(false);
		OwnerMesh = USkeletalMeshComponent::Get(Owner);
		HoldWidget = Cast<UParentBlobKineticWidget>(Game::GetMay().AddWidget(WidgetClass));
		HoldWidget.SetWidgetPersistent(true);
		Game::GetMay().RemoveWidget(HoldWidget);

		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			auto KineticInputVisualizerClass = Player.IsMay() ? KineticInputVisualizerClassMay : KineticInputVisualizerClassCody;
			auto& KineticInputVisualizer = KineticInputVisualizers[int(Player.Player)];
			KineticInputVisualizer = Cast<AKineticInputVisualizer>(SpawnPersistentActor(KineticInputVisualizerClass));
			KineticInputVisualizer.SetOwner(Owner);
			KineticInputVisualizer.AttachRootComponentToActor(Owner, NAME_None, EAttachLocation::SnapToTarget);
			KineticInputVisualizer.SetActorTransform(GetVisualizerAttachmentTransform(Player));
			KineticInputVisualizer.Status = EKineticInputVisualizerStatus::ActiveWithNoTarget;
			KineticInputVisualizer.SetStatus(EKineticInputVisualizerStatus::Inactive);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(int i = 0; i < 2; ++i)
		{
			auto KineticInputVisualizer = KineticInputVisualizers[i];
			if(KineticInputVisualizer == nullptr)
				continue;
			
			KineticInputVisualizer.DestroyActor();
			KineticInputVisualizers[i] = nullptr;
		}

		HoldWidget.SetWidgetPersistent(false);
		Game::GetMay().RemoveWidget(HoldWidget);
		HoldWidget = nullptr;
		bWidgetIsVisible = false;
	}

	FTransform GetVisualizerAttachmentTransform(AHazePlayerCharacter ForPlayer) const
	{
		FTransform Transform = Owner.GetActorTransform();

		// TODO, change to getter
		auto AttachSettings = DefaultInputSettings;
		if(AttachSettings == nullptr)
			return Transform;

		const FParentBlobKineticInputSettingsData& AttachPlayerSettings = ForPlayer.IsMay() ? AttachSettings.MaySettings : AttachSettings.CodySettings;
		const FParentBlobKineticPlayerInputData& InputData = PlayerInputData[int(ForPlayer.Player)];

		if(AttachPlayerSettings.AttachBoneName != NAME_None)
			Transform.SetLocation(OwnerMesh.GetSocketLocation(AttachPlayerSettings.AttachBoneName));
		
		FVector AttachOffset = AttachPlayerSettings.AttachOffset;
		Transform.AddToTranslation(Transform.TransformVector(AttachOffset));
		
		if(InputData.bSteeringIsToFindInteraction && InputData.bHasSteeringInput)
		{
			const float HeightOffset = AttachSettings.HeightOffsetInRelationToInputAngle.GetFloatValue(InputData.InputAngle);
			Transform.AddToTranslation(FVector(0.f, 0.f, HeightOffset));

			Transform.SetRotation(Transform.TransformRotation(FRotator(0.f, InputData.InputAngle, 0.f).Quaternion()));
			const float ForwardOffset = AttachSettings.ForwardOffsetInRelationToInputAngle.GetFloatValue(InputData.InputAngle);
			Transform.AddToTranslation(Transform.Rotation.ForwardVector * ForwardOffset);
		}
		
		return Transform;
	}

	void ShowWidget(UParentBlobKineticInteractionComponent ActiveInteraction)
	{
		if(!bWidgetIsVisible)
		{
			bWidgetIsVisible = true;
			Game::GetMay().AddExistingWidget(HoldWidget);
		}

		HoldWidget.AttachWidgetToComponent(ActiveInteraction);
		HoldWidget.InitalizeKineticWidget(ActiveInteraction.IconVisibility, ActiveInteraction.bHasBeenInteractedWith);
		HoldWidget.SetVisibilityType(EParentBlobKineticInteractionStatus::OutOfReach);
		InteractionStatus = EParentBlobKineticInteractionStatus::OutOfReach;
		HoldWidget.MayProgress = 0;
		HoldWidget.CodyProgress = 0;
	}

	void HideWidget()
	{
		if(bWidgetIsVisible)
		{
			bWidgetIsVisible = false;
			Game::GetMay().RemoveWidget(HoldWidget);
		}
	}

	bool PlayerIsHolding(EHazePlayer Player, UParentBlobKineticInteractionComponent OptionalInteraction = nullptr) const
	{
		if(OptionalInteraction != nullptr && PlayerInputData[Player].TargetedInteraction != OptionalInteraction)
			return false;
		return PlayerInputData[Player].bIsHolding;
	}

	bool PlayerHasValidInput(EHazePlayer Player, UParentBlobKineticInteractionComponent OptionalInteraction) const
	{
		// No input required
		if(!PlayerInputData[Player].InputRequiredToActivateInteraction)
			return true;

		if(!PlayerInputData[Player].bHasSteeringInput)
			return false;

		if(OptionalInteraction == nullptr || OptionalInteraction != PlayerInputData[Player].TargetedInteraction)
			return false;

		if(!PlayerInputData[Player].InputIsValidToRequiredAngle)
			return false;
	
		return true;
	}

	AKineticInputVisualizer GetKineticVisualizer(AHazePlayerCharacter ForPlayer) const
	{
		return KineticInputVisualizers[int(ForPlayer.Player)];
	}
}
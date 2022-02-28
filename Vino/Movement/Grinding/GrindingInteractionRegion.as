import Vino.Movement.Grinding.GrindingBaseRegionComponent;
import Vino.Interactions.Widgets.InteractionWidget;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Interactions.Widgets.InteractionWidgetsComponent;

namespace GrindInteractSyncNames
{
	const FName ActiveRegion = n"GrindInteractionActivationRegion";
	const FName InteractionPressed = n"GrindInteractionInputButtonWasPressed";
}

namespace GrindInteractAnim
{
	const FName TriggerButtonHit = n"GrindInteractionHitButton";
	const FName DistanceToButton = n"GrindInteractionDistanceToButton";
}

class UNewGrindingInteractionCapability : UHazeCapability
{
	UHazeSplineFollowComponent FollowComp;
	AHazePlayerCharacter OwningPlayer;

	UHazeMovementComponent MoveComp;

	UNewGrindingInteractionRegion ActivationRegion;
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	bool bHasPressedInteraction = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		FollowComp = UHazeSplineFollowComponent::GetOrCreate(Owner);
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		ensure(OwningPlayer != nullptr);

		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Check if we are inside a Grind Activation Region.
		if (IsActive())
			return;
		
		if (IsBlocked())
			return;

		ActivationRegion = Cast<UNewGrindingInteractionRegion>(FollowComp.GetActiveRegionType(UNewGrindingInteractionRegion::StaticClass()));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (ActivationRegion == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!ActivationRegion.CanTriggerInputAtDistance(FollowComp.Position.DistanceAlongSpline))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;
		
		if (!FollowComp.HasActiveSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (bHasPressedInteraction)
		{
			if (ActivationRegion.IsActorWithinRegion(Owner))
				return EHazeNetworkDeactivation::DontDeactivate;
		}
		else if(ActivationRegion.CanTriggerInputAtDistance(FollowComp.Position.DistanceAlongSpline))
		{
			return EHazeNetworkDeactivation::DontDeactivate;	
		}

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		SyncParams.AddObject(GrindInteractSyncNames::ActiveRegion, ActivationRegion);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActivationRegion = Cast<UNewGrindingInteractionRegion>(ActivationParams.GetObject(GrindInteractSyncNames::ActiveRegion));
		ensure(ActivationRegion != nullptr);

		ActivationRegion.AddActivePlayer(OwningPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		if (bHasPressedInteraction)
			DeactivationParams.AddActionState(GrindInteractSyncNames::InteractionPressed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (DeactivationParams.GetActionState(GrindInteractSyncNames::InteractionPressed))
		{
			ActivationRegion.OnInteractionTrigger(OwningPlayer);
			UpdateAnimation(true);

			if (HasControl())
				Owner.UnblockCapabilities(GrindingCapabilityTags::GrindMoveAction, this);
		}

		ActivationRegion.StopShowingWidgetForPlayer(OwningPlayer);
		bHasPressedInteraction = false;
		ActivationRegion = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bHasPressedInteraction)
		{
			UpdateAnimation(false);
			return;
		}
		
		if (!WasActionStarted(ActionNames::InteractionTrigger))
			return;

		OnInputTriggered();
	}

	void OnInputTriggered()
	{
		bHasPressedInteraction = true;
		ActivationRegion.StopShowingWidgetForPlayer(OwningPlayer);

		if (HasControl())
			Owner.BlockCapabilities(GrindingCapabilityTags::GrindMoveAction, this);
	}

	void UpdateAnimation(bool bTriggerButtonHit)
	{
		if (ActivationRegion.FeatureToRequestOnActivation == NAME_None)
			return;

		MoveComp.SetAnimationToBeRequested(ActivationRegion.FeatureToRequestOnActivation);
		float DistanceToButton = (ActivationRegion.WidgetInteractionLocation - MoveComp.OwnerLocation).Size();

		OwningPlayer.SetAnimFloatParam(GrindInteractAnim::DistanceToButton, DistanceToButton);
		OwningPlayer.SetAnimBoolParam(GrindInteractAnim::TriggerButtonHit, bTriggerButtonHit);
	}
}

delegate void FRegionInteractionActivated(UNewGrindingInteractionRegion RegionActivated, AHazePlayerCharacter ActivatingPlayer);
class UNewGrindingInteractionRegion : UGrindingBaseRegionComponent
{
	UPROPERTY()
	TSubclassOf<UInteractionWidget> WidgetClass = Asset("/Game/Blueprints/Interactions/WBP_InteractionWidget.WBP_InteractionWidget_C");

	UPROPERTY(Category = WidgetLocation, Meta = (MakeEditWidget))
	FTransform WidgetLocation;

	UPROPERTY()
	FRegionInteractionActivated OnRegionInteractionActivated;

	UPROPERTY()
	FName FeatureToRequestOnActivation = n"GrindButton";

	// If the player is this far from the end then they can no longer give the input to trigger the interaction.
	UPROPERTY()
	float DisableInputDistance = 50.f;

	TArray<AHazePlayerCharacter> PlayersOnSpline;
	TArray<AHazePlayerCharacter> ActivePlayers;

	UFUNCTION(BlueprintOverride)
	void ActorEnteredOwnerSpline(AHazeActor EnteringActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(EnteringActor);
		if (Player == nullptr)
			return;

		PlayersOnSpline.AddUnique(Player);
		ComponentTickEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void ActorLeftOwnerSpline(AHazeActor LeavingActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(LeavingActor);
		if (Player == nullptr)
			return;

		StopShowingWidgetForPlayer(Player);
	}

	void StopShowingWidgetForPlayer(AHazePlayerCharacter Player)
	{
		PlayersOnSpline.RemoveSwap(Player);
		if (PlayersOnSpline.Num() <= 0)
			ComponentTickEnabled = false;

		RemoveActivePlayer(Player);
	}

	void AddActivePlayer(AHazePlayerCharacter ActivePlayer)
	{
		ActivePlayers.AddUnique(ActivePlayer);
	}

	void RemoveActivePlayer(AHazePlayerCharacter InactivePlayer)
	{
		ActivePlayers.RemoveSwap(InactivePlayer);
	}
	
	bool CanTriggerInputAtDistance(float Distance)
	{
		if (!IsDistanceWithinRegion(Distance))
			return false;

		float DisableStart = EndPosition.DistanceAlongSpline - DisableInputDistance;
		return Distance < DisableStart;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (auto Player : PlayersOnSpline)
		{
			bool bActive = false;
			for (auto ActivePlayer : ActivePlayers)
			{
				if (ActivePlayer == Player)
				{
					bActive = true;
					break;
				}
			}

			UInteractionWidgetsComponent WidgetComp = UInteractionWidgetsComponent::Get(Player);
			if (WidgetComp == nullptr)
				continue;
			
			WidgetComp.ShowInteractionWidgetThisFrame(this, bActive, bActive, EHazeActivationType::Action, WidgetLocation.Location);
		}
	}

	UFUNCTION()
	void BindOnInteractionActivated(FRegionInteractionActivated Event)
	{
		OnRegionInteractionActivated = Event;
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionInitialized()
	{
		WidgetLocation.Location = Owner.ActorTransform.InverseTransformPosition(GetEndPointLocation());
	}

	UFUNCTION()
	FVector GetWidgetInteractionLocation() property
	{
		return WorldTransform.TransformPosition(WidgetLocation.Location);
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const property
	{
		return FLinearColor::Green;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilityRequest(UNewGrindingInteractionCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(UNewGrindingInteractionCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	bool CanActorEnterRegion(AHazeActor EnteringActor, float CurrentDistance, float PreviousDistance, bool bTravelingForward) const
	{
		if (!WidgetClass.IsValid())
			return false;

		if (Cast<AHazePlayerCharacter>(EnteringActor) == nullptr)
			return false;

		return Super::CanActorEnterRegion(EnteringActor, CurrentDistance, PreviousDistance, bTravelingForward);
	}

	//Happens when the player has pressed the interact button and has left the region.
	void OnInteractionTrigger(AHazePlayerCharacter ActivatingPlayer)
	{
		OnRegionInteractionActivated.ExecuteIfBound(this, ActivatingPlayer);
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void ResetTargetLocationToStart()
	{
		WidgetLocation.Location = WorldTransform.InverseTransformPosition((StartPointLocation)) + FVector::UpVector * 250.f;
		Editor::RedrawAllViewports();
	}
#endif
}

#if EDITOR
class UNewGrindingInteractionRegionVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UNewGrindingInteractionRegion::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent ActorComp)
	{
		UNewGrindingInteractionRegion Region = Cast<UNewGrindingInteractionRegion>(ActorComp);
		if (Region == nullptr)
			return;

		if (Region.DisableInputDistance < 0.f)
			Region.DisableInputDistance = 0.f;

		float RegionDistance = Region.EndPosition.DistanceAlongSpline - Region.StartPosition.DistanceAlongSpline;
		if (Region.DisableInputDistance > RegionDistance)
			Region.DisableInputDistance = RegionDistance;

		FHazeSplineSystemPosition InteractPoint = Region.EndPosition;
		InteractPoint.Reverse();
		InteractPoint.Move(Region.DisableInputDistance);

		FVector Offset = FVector::UpVector * 160.f;
		
		DrawWireSphere(InteractPoint.WorldLocation + Offset, 25.f, FLinearColor::Red);

		const float DeltaDistance = (Region.EndPosition.DistanceAlongSpline - InteractPoint.DistanceAlongSpline);
		if (DeltaDistance < 10.f)
			return;

		float StepDistance = DeltaDistance / 10.f;
		FHazeSplineSystemPosition LinePoint = Region.EndPosition;
		LinePoint.Reverse();
		FVector StartDrawPoint = LinePoint.WorldLocation + Offset;
		for (int ICount = 10; ICount > 0; --ICount)
		{
			LinePoint.Move(StepDistance);
			const FVector DrawTo = LinePoint.WorldLocation + Offset;

			DrawLine(StartDrawPoint, DrawTo, FLinearColor::Red);
			StartDrawPoint = DrawTo;
		}
	}

}
#endif

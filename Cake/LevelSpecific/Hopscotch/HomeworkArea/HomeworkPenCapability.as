import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkPen;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkPenAnimationDataComponent;

class UHomeworkPenCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(n"GameplayAction");

	default CapabilityDebugCategory = n"HomeworkPen";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	UPROPERTY()
	ULocomotionFeatureHomeworkPen CodyFeature;

	UPROPERTY()
	ULocomotionFeatureHomeworkPen MayFeature;

	AHazePlayerCharacter Player;
	USceneComponent AttachComp;
	UHomeworkPenAnimationDataComponent AnimData;

	AHomeworkPen Pen;
	UInteractionComponent InteractionPoint;
	int Direction;
	bool bFullyEntered;

	FRotator PenRelativeRot = FRotator::ZeroRotator;
	FRotator PenRelativeRotLastTick = FRotator::ZeroRotator;

	bool bStop = false;

	float InterpedXDelta;
	float InterpedYDelta;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AnimData = UHomeworkPenAnimationDataComponent::GetOrCreate(Player, n"HomeworkPenAnimationData");

		if (Player == Game::GetCody())
			Player.AddLocomotionFeature(CodyFeature);
		else
			Player.AddLocomotionFeature(MayFeature);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
       if (GetAttributeObject(n"HomeworkPen") != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		else
        	return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetAttributeObject(n"HomeworkPen") == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (bStop)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"Pen", GetAttributeObject(n"HomeworkPen"));
		Params.AddObject(n"InteractComp", GetAttributeObject(n"PenInteractionComp"));
		Params.AddObject(n"AttachComp", GetAttributeObject(n"PenAttachComp"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bStop = false;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		InteractionPoint = Cast<UInteractionComponent>(ActivationParams.GetObject(n"InteractComp"));
		Pen = Cast<AHomeworkPen>(ActivationParams.GetObject(n"Pen"));
		AttachComp = Cast<USceneComponent>(ActivationParams.GetObject(n"AttachComp"));
		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);
		Player.AttachToComponent(AttachComp, n"", EAttachmentRule::SnapToTarget);
		
		Direction = GetAttributeNumber(n"Direction");
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (Player == Game::GetCody())
			Player.RemoveLocomotionFeature(CodyFeature);
		else
			Player.RemoveLocomotionFeature(MayFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Pen.DetachFromPen(Player, InteractionPoint);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockMovementSyncronization(this);
		Pen = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// UObject PenTemp;
		// if (ConsumeAttribute(n"Pen", PenTemp))
		// 	Pen = Cast<AHomeworkPen>(PenTemp);		
    }	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		FHazeRequestLocomotionData LocoData;
		LocoData.AnimationTag = n"HomeworkPen";
		Player.RequestLocomotion(LocoData);
		
		AnimData.bShouldFlipDirection = Direction == 0 ? true : false; 
		float MappedXDelta;
		float MappedYDelta;
		
		if (Pen != nullptr)
		{
			InterpedXDelta = FMath::FInterpTo(InterpedXDelta, Pen.PenDelta2D.X, DeltaTime, 8.f);
			MappedXDelta = FMath::GetMappedRangeValueClamped(FVector2D(-150.f, 150.f), FVector2D(-2.f, 2.f), InterpedXDelta);

			InterpedYDelta = FMath::FInterpTo(InterpedYDelta, Pen.PenDelta2D.Y, DeltaTime, 8.f);
			MappedYDelta = FMath::GetMappedRangeValueClamped(FVector2D(-150.f, 150.f), FVector2D(-2.f, 2.f), InterpedYDelta);
		}

		FVector2D InterpedDelta = FVector2D(MappedXDelta, MappedYDelta);
		AnimData.CurrentDirection = InterpedDelta;

		if (Pen != nullptr && HasControl())
		{
			if (Direction == 0)
			{
				FVector HorizontalStick = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
				Pen.MovePenHorizontal(-HorizontalStick.X, Player);	
				PrintToScreen("HorizontalStick: " + HorizontalStick);
				PenRelativeRot.Roll = (-HorizontalStick.X * 2.f) * InterpedDelta.X;

			} else if (Direction == 1)
			{
				FVector VerticalStick = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
				Pen.MovePenVertical(-VerticalStick.Y, Player);
				PenRelativeRot.Pitch = (VerticalStick.Y * 2.f) * InterpedDelta.Y;
			}

			PenRelativeRot = FMath::RInterpTo(PenRelativeRotLastTick, PenRelativeRot, DeltaTime, 15.f);
			PrintToScreen("PenRelativeRot: " + PenRelativeRot);
			Pen.PenRoot.SetRelativeRotation(PenRelativeRot);
			PenRelativeRotLastTick = Pen.PenRoot.RelativeRotation;
		}

		if (IsActioning(ActionNames::Cancel))
			bStop = true;
	}
}
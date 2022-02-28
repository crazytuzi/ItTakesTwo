import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldWidget;

class UParentBlobButtonHoldCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"ParentBlobButtonHold");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AParentBlob ParentBlob;
	UParentBlobButtonHoldComponent HoldComp;
	UParentBlobButtonHoldWidget HoldWidget;
	
	const float HoldProgressSpeed = 0.4f;
	const float HoldDecaySpeed = 1.f;

	float MayHoldProgress = 0.f;
	float CodyHoldProgress = 0.f;
	float TotalHoldProgress = 0.f;

	bool bHoldCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		HoldComp = UParentBlobButtonHoldComponent::GetOrCreate(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HoldComp.bButtonHoldActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HoldComp.bButtonHoldActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bHoldCompleted)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bHoldCompleted = false;

		MayHoldProgress = 0.f;
		CodyHoldProgress = 0.f;
		TotalHoldProgress = 0.f;
		HoldComp.UpdateCurrentProgress(TotalHoldProgress);

		HoldWidget = Cast<UParentBlobButtonHoldWidget>(Game::GetMay().AddWidget(HoldComp.WidgetClass));
		if (HoldComp.AttachComp != nullptr)
			HoldWidget.AttachWidgetToComponent(HoldComp.AttachComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HoldComp.bButtonHoldActive = false;

		if (bHoldCompleted)
			HoldComp.ButtonHoldCompleted();

		if (HoldWidget != nullptr)
		{
			Game::GetMay().RemoveWidget(HoldWidget);
			HoldWidget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HoldComp.bMayHolding)
			MayHoldProgress += HoldProgressSpeed * DeltaTime;
		else
			MayHoldProgress -= HoldDecaySpeed * DeltaTime;

		MayHoldProgress = FMath::Clamp(MayHoldProgress, 0.f, 1.f);
		HoldComp.MayHoldProgress = MayHoldProgress;

		if (HoldComp.bCodyHolding)
			CodyHoldProgress += HoldProgressSpeed * DeltaTime;
		else
			CodyHoldProgress -= HoldDecaySpeed * DeltaTime;

		CodyHoldProgress = FMath::Clamp(CodyHoldProgress, 0.f, 1.f);
		HoldComp.CodyHoldProgress = CodyHoldProgress;

		TotalHoldProgress = (MayHoldProgress + CodyHoldProgress)/2;
		HoldComp.UpdateCurrentProgress(TotalHoldProgress);
		HoldWidget.MayProgress = MayHoldProgress;
		HoldWidget.CodyProgress = CodyHoldProgress;
		HoldWidget.TotalProgress = TotalHoldProgress;

		if (TotalHoldProgress == 1)
			bHoldCompleted = true;
	}
}
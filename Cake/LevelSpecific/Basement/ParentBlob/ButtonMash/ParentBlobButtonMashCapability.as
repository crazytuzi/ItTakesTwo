import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonMash.ParentBlobButtonMashComponent;

class UParentBlobButtonMashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AParentBlob ParentBlob;
	UParentBlobButtonMashComponent MashComp;
	UButtonMashDefaultHandle MayMashHandle;
	UButtonMashDefaultHandle CodyMashHandle;

	const float ProgressPerMash = 0.05f;
	const float ProgressDecaySpeed = 0.1f;

	float MayMashProgress = 0.f;
	float CodyMashProgress = 0.f;
	float TotalMashProgress = 0.f;

	bool bMashCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		MashComp = UParentBlobButtonMashComponent::GetOrCreate(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MashComp.bButtonMashActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MashComp.bButtonMashActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bMashCompleted)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bMashCompleted = false;

		MayMashProgress = 0.f;
		CodyMashProgress = 0.f;
		TotalMashProgress = 0.f;
		MashComp.UpdateCurrentProgress(TotalMashProgress);

		MayMashHandle = Game::GetMay().StartButtonMashDefaultAttachToComponent(ParentBlob.Mesh, n"LeftHand", FVector::ZeroVector);
		CodyMashHandle = Game::GetCody().StartButtonMashDefaultAttachToComponent(ParentBlob.Mesh, n"RightHand", FVector::ZeroVector);
		MashComp.SetButtonMashHandles(MayMashHandle, CodyMashHandle);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopButtonMash(MayMashHandle);
		StopButtonMash(CodyMashHandle);

		MashComp.bButtonMashActive = false;

		if (bMashCompleted)
			MashComp.ButtonMashCompleted();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MayMashProgress += (MayMashHandle.MashRateControlSide * ProgressPerMash * DeltaTime);
		MayMashProgress -= ProgressDecaySpeed * DeltaTime;
		MayMashProgress = FMath::Clamp(MayMashProgress, 0.f, 0.5f);
		MashComp.MayMashProgress = MayMashProgress;

		CodyMashProgress += (CodyMashHandle.MashRateControlSide * ProgressPerMash * DeltaTime);
		CodyMashProgress -= ProgressDecaySpeed * DeltaTime;
		CodyMashProgress = FMath::Clamp(CodyMashProgress, 0.f, 0.5f);
		MashComp.CodyMashProgress = CodyMashProgress;

		TotalMashProgress = MayMashProgress + CodyMashProgress;
		MashComp.UpdateCurrentProgress(TotalMashProgress);

		if (TotalMashProgress == 1)
			bMashCompleted = true;
	}
}
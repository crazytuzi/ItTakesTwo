import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortal;
import Effects.PostProcess.PostProcessing;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortalComponent;
import Peanuts.Fades.FadeStatics;

class USpacePortalEnterCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	bool bPortalEntered = false;

	ASpacePortal CurrentPortal;
	UHazeCameraComponent CurrentCamera;
	UStaticMeshComponent CurrentEntryPlane;
	USpacePortalComponent PortalComp;

	UPROPERTY()
	FHazeTimeLike FieldOfViewTimeLike;
	default FieldOfViewTimeLike.Duration = 0.4f;

	UPROPERTY()
	FHazeTimeLike MoveCameraTimeLike;
	default MoveCameraTimeLike.Duration = 0.65f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		FieldOfViewTimeLike.BindUpdate(this, n"UpdateFoV");
		FieldOfViewTimeLike.BindFinished(this, n"FinishFoV");

		MoveCameraTimeLike.BindUpdate(this, n"UpdateMoveCamera");
		MoveCameraTimeLike.BindFinished(this,n"FinishMoveCamera");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"EnterSpacePortal"))
        	return EHazeNetworkActivation::ActivateUsingCrumb;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bPortalEntered)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPortalEntered = false;
		Player.SetCapabilityActionState(n"EnterSpacePortal", EHazeActionState::Inactive);
		CurrentPortal = Cast<ASpacePortal>(GetAttributeObject(n"CurrentPortal"));
		PortalComp = USpacePortalComponent::Get(Player);
		
		CurrentCamera = Player.IsMay() ? CurrentPortal.MayCamera : CurrentPortal.CodyCamera;

		if (CurrentPortal.bActivateEntryCamera)
		{
			FHazeCameraBlendSettings CamBlend;
			CamBlend.BlendTime = 0.5f;
			Player.ActivateCamera(CurrentCamera, CamBlend, this, EHazeCameraPriority::Maximum);
		}

		FieldOfViewTimeLike.PlayFromStart();

		PortalComp.EffectActor.Activate(true);
		PortalComp.EnterPortal(CurrentPortal.TargetStation, CurrentPortal.ActorLocation);

		if (Player.IsCody())
			Player.BlockCapabilities(n"ChangeSize", this);

		Player.PlayForceFeedback(PortalComp.EnterRumble, false, true, n"PortalEnter");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bPortalEntered = false;
		Player.SetCapabilityActionState(n"SpacePortaling", EHazeActionState::Active);
		Player.DeactivateCamera(CurrentCamera, 0.f);
		Player.ClearFieldOfViewByInstigator(this, 0.f);
		CurrentCamera.SetRelativeLocation(FVector(600.f, 0.f, 700.f));

		if (Player.IsCody())
			Player.UnblockCapabilities(n"ChangeSize", this);
	}

	UFUNCTION()
	void UpdateFoV(float CurValue)
	{
		float CurFoV = FMath::Lerp(70.f, 140.f, CurValue);
		FHazeCameraBlendSettings FoVBlend;
		FoVBlend.BlendTime = 0.1f;
		Player.ApplyFieldOfView(CurFoV, FoVBlend, this);
	}

	UFUNCTION()
	void FinishFoV()
	{
		MoveCameraTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateMoveCamera(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector(600.f, 0.f, 700.f), FVector(-1400.f, 0.f, 700.f), CurValue);
		CurrentCamera.SetRelativeLocation(CurLoc);
	}

	UFUNCTION()
	void FinishMoveCamera()
	{
		bPortalEntered = true;
	}
}
import Peanuts.Audio.AudioStatics;

class UFullScreenPanningCapability : UHazeCapability
{
	UHazeAkComponent HazeAkComp;
	private float LastScreenPosX;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HazeAkComp = UHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HazeAkComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!SceneView::IsFullScreen())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D ScreenPos;
		if(SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), Owner.GetActorLocation(), ScreenPos))
		{
			const float NormalizedScreenPosX = HazeAudio::NormalizeRTPC(ScreenPos.X, 0.f, 1.f, -1.f, 1.f);
			if(NormalizedScreenPosX != LastScreenPosX)
			{
				HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, NormalizedScreenPosX);
				LastScreenPosX = NormalizedScreenPosX;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(HazeAkComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!SceneView::IsFullScreen())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;	
	}	
}
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Actors.StaticCamera;
import Peanuts.Fades.FadeManagerComponent;
import Peanuts.Subtitles.SubtitleManagerComponent;

class AMenuCameraUser : AHazeMenuCameraUser
{
	UPROPERTY(DefaultComponent)
	UHazeActiveCameraUserComponent CameraUserComp;	

	UPROPERTY(DefaultComponent)
	UFadeManagerComponent FadeManagerComponent;

	UPROPERTY(DefaultComponent)
	USubtitleManagerComponent SubtitleComponent;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;
	default PrimaryActorTick.bTickEvenWhenPaused = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FadeManagerComponent.AddFade(-1.0f, 0.0f, 0.0f, EFadePriority::Gameplay);
	}

	UFUNCTION()
	void FadeInView(float FadeDuration)
	{
		FadeManagerComponent.ClearAllFades(FadeDuration, EFadePriority::Gameplay);
	}

	UFUNCTION()
	void FadeOutView(float FadeOutTime)
	{
		FadeManagerComponent.AddFade(-1.f, FadeOutTime, 0.f, EFadePriority::Gameplay);
	}

	UFUNCTION()
	void AddTemporaryFade(float FadeOutTime, float FadeDuration, float FadeInTime)
	{
		FadeManagerComponent.AddFade(FadeDuration, FadeOutTime, FadeInTime, EFadePriority::Gameplay);
	}

	UFUNCTION()
	void SnapToCamera(AStaticCamera Camera)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.f;
		DeactivateCameraByInstigator(this, Blend);
		ActivateCamera(Camera.Camera, Blend, this, EHazeCameraPriority::Minimum);
	}

	UFUNCTION()
	void BlendToCamera(AStaticCamera Camera, float BlendTime)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = BlendTime;
		DeactivateCameraByInstigator(this, Blend);
		ActivateCamera(Camera.Camera, Blend, this, EHazeCameraPriority::Minimum);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CameraUserComp.Update(DeltaTime);
	}
};
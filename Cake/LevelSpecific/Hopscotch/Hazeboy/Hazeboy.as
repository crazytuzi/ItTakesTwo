import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;

import void StartUsingHazeboy(AHazePlayerCharacter Player, AHazeboy Device) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyPlayerComponent';

class AHazeboy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent UserCamera;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY(EditInstanceOnly, Category = "Hazeboy")
	AHazeboyTank TargetTank;

	UPROPERTY(EditDefaultsOnly, Category = "Hazeboy")
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY(EditDefaultsOnly, Category = "Hazeboy|Screen")
	UMaterial ScreenMaterialBase;

	UPROPERTY(EditDefaultsOnly, Category = "Hazeboy|Screen")
	int PixelResolution = 128;

	UPROPERTY(EditDefaultsOnly, Category = "Hazeboy|Screen")
	int UpscaleResolution = 1024;

	UTextureRenderTarget2D UpscaleRenderTexture;
	UTextureRenderTarget2D ScreenTexture;

	UMaterialInstanceDynamic ScreenMaterial;
	UMaterialInstanceDynamic DownscaleMaterial;

	AHazePlayerCharacter InteractedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpscaleRenderTexture = Rendering::CreateRenderTarget2D(UpscaleResolution, UpscaleResolution, ETextureRenderTargetFormat::RTF_RGBA16f, FLinearColor::Black, false);
		UpscaleRenderTexture.Filter = TextureFilter::TF_Nearest;

		ScreenTexture = Rendering::CreateRenderTarget2D(PixelResolution, PixelResolution, ETextureRenderTargetFormat::RTF_RGBA16f, FLinearColor::Black, false);
		ScreenTexture.Filter = TextureFilter::TF_Nearest;

		ScreenMaterial = Material::CreateDynamicMaterialInstance(ScreenMaterialBase);
		ScreenMaterial.SetTextureParameterValue(n"ScreenTexture", ScreenTexture);

		DownscaleMaterial = Material::CreateDynamicMaterialInstance(ScreenMaterialBase);
		DownscaleMaterial.SetTextureParameterValue(n"ScreenTexture", UpscaleRenderTexture);

		Mesh.SetMaterial(1, ScreenMaterial);

		if (TargetTank != nullptr)
			TargetTank.Camera.TextureTarget = UpscaleRenderTexture;

		InteractionComp.OnActivated.AddUFunction(this, n"HandleInteraction");
	}

	UFUNCTION()
	void HandleInteraction(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		Player.StartUsingHazeboy(this);
		OnPlayerLandHazeBoy(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Rendering::DrawMaterialToRenderTarget(ScreenTexture, DownscaleMaterial);
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerLandHazeBoy(AHazePlayerCharacter Player)
	{
		
	}
}
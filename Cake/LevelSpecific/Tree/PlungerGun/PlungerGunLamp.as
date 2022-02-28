import AHazePlayerCharacter PlungerGunGetFrontPlayer() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import AHazePlayerCharacter PlungerGunGetBackPlayer() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';

UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData Debug LOD")
class APlungerGunLamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UPointLightComponent Light;

	UPROPERTY(EditInstanceOnly, Category = "Lamp")
	bool bForward = true;

	UPROPERTY(EditDefaultsOnly, Category = "Lamp")
	FHazeTimeLike GlowTimeLike;

	UMaterialInstanceDynamic LampMaterial;

	FLinearColor BaseEmissive;
	float BaseIntensity;

	bool bIsLit = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AActor Parent = GetAttachParentActor();
		if (Parent == nullptr)
			return;

		auto Spline = UHazeSplineComponentBase::Get(Parent);
		if (Spline == nullptr)
			return;

		FHazeSplineSystemPosition AttachPosition;
		if (bForward) 
			AttachPosition = Spline.GetPositionAtEnd(true);
		else
			AttachPosition = Spline.GetPositionAtStart(false);

		Root.RelativeTransform = AttachPosition.RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LampMaterial = Mesh.CreateDynamicMaterialInstance(0);

		BaseEmissive = LampMaterial.GetVectorParameterValue(n"Emissive Tint");
		BaseIntensity = Light.Intensity;

		LampMaterial.SetVectorParameterValue(n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.f));
		Light.SetIntensity(0.f);

		GlowTimeLike.BindUpdate(this, n"HandleTimeLikeUpdate");
		GlowTimeLike.BindFinished(this, n"HandleTimeLikeFinished");
	}

	void LightUp()
	{
		GlowTimeLike.PlayFromStart();
		bIsLit = true;

		BP_OnTurnOn();
	}

	UFUNCTION()
	void HandleTimeLikeUpdate(float Value)
	{
		LampMaterial.SetVectorParameterValue(n"Emissive Tint", BaseEmissive * Value);
		Light.SetIntensity(BaseIntensity * Value);
	}

	UFUNCTION()
	void HandleTimeLikeFinished()
	{
		if (bIsLit)
		{
			GlowTimeLike.ReverseFromEnd();
			bIsLit = false;
		}
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPlayerClosestToLamp()
	{
		return bForward ? PlungerGunGetFrontPlayer() : PlungerGunGetBackPlayer();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTurnOn()
	{
	}
}
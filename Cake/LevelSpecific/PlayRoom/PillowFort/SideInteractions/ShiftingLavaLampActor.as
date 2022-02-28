import Cake.Environment.HazeSphere;
import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;

event void FOnTriggerLavaLampVO(bool TriggerMayVO);

/* 
	Shrink together via Time prior to shifting shape settings?


*/
//

enum ELavaLampColor
{
	Green,
	Blue,
	Orange,
	Yellow,
	Custom
}

struct FLavaLampSettings
{
	UPROPERTY()
	FLinearColor Color = FLinearColor(0, 0, 0, 1.f);
	UPROPERTY()
	float BlobOffset = 5.f;
	UPROPERTY()
	float BlobSize = 0.1f;
	UPROPERTY()
	float BlobBlending = 10.f;
	UPROPERTY()
	float EmissiveGradientOffset = -400.f;
	UPROPERTY()
	float Boxness = 0.f;
	UPROPERTY()
	float StartingBlobSize = 0.23f;
	UPROPERTY()
	float LampHeightMultiplier = 0.6f;
	UPROPERTY()
	ELavaLampColor ColorState;
}

class AShiftingLavaLampActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LampMesh;

	UPROPERTY(DefaultComponent, Attach = InteractComp)
	USceneComponent InteractionLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent PointLightComp;
	default PointLightComp.RelativeLocation = FVector(0,0,300);
	default PointLightComp.SetCastShadows(false);
	default PointLightComp.Mobility = EComponentMobility::Movable;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.f;

	UPROPERTY(Category = "ShapeSettings")
	TArray<FLavaLampSettings> ShapePresets;

	UPROPERTY(EditDefaultsOnly ,Category = "ShapeSettings")
	FHazeTimeLike BlendTimeLike;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UForceFeedbackEffect OnInteractForceFeedback;

	UPROPERTY(Category = "Setup")
	int LavaMaterialIndex = 2;

	UPROPERTY(Category = "Lighting")
	bool bUsePointLight = false;
	UPROPERTY(Category = "Setup")
	bool AnimationHasAlignInfo = false;

	UPROPERTY(EditInstanceOnly ,Category = "Setup")
	AHazeSphere HazeSphere;

	UPROPERTY(Category = "Setup")
	UAnimSequence CodyAnim;
	UPROPERTY(Category = "Setup")
	UAnimSequence MayAnim;

	UPROPERTY(Category = "Setup")
	int ButtonMaterialIndex = 1;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent LavaLampHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayLavaLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayInteractAudioEvent;

	UPROPERTY()
	FOnTriggerLavaLampVO OnTriggerLavaLampVOEvent;

	AHazePlayerCharacter InteractingPlayer;

	UMaterialInstanceDynamic ButtonMaterialInstance;
	UMaterialInstanceDynamic DynMaterial;

	FHazeAnimNotifyDelegate AnimNotifyDelegate;
	FLavaLampSettings TargetShape;
	FLavaLampSettings CurrentShape;

	UPROPERTY(Category = "Setup")
	FLavaLampSettings DefaultShape;

	int ShapeIndex = 0;
	int TargetIndex = 0;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(!bUsePointLight)
			PointLightComp.SetActive(false);

		//DynMaterial = LampMesh.CreateDynamicMaterialInstance(LavaMaterialIndex);

		if(DefaultShape.ColorState != ELavaLampColor::Custom)
		{
			SetShape(GetShapeIndexFromState(DefaultShape.ColorState));
		}
		else
		{
			SetLinearColorParam(n"Color", DefaultShape.Color);
			SetScalarParam(n"BlobOffset", DefaultShape.BlobOffset);
			SetScalarParam(n"BlobSize", DefaultShape.BlobSize);
			SetScalarParam(n"BlobBlending", DefaultShape.BlobBlending);
			SetScalarParam(n"Boxness", DefaultShape.Boxness);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BlendTimeLike.BindUpdate(this, n"OnTimeLikeUpdate");
		BlendTimeLike.BindFinished(this, n"OnTimeLikeFinished");

		InteractComp.OnActivated.AddUFunction(this, n"OnInteracted");

		LavaLampHazeAkComp.HazePostEvent(PlayLavaLoopAudioEvent);

		if(DefaultShape.ColorState == ELavaLampColor::Custom)
			SaveDefaultShape();

		if(bUsePointLight)
			PointLightComp.SetLightColor(CurrentShape.Color);

		ButtonMaterialInstance = LampMesh.CreateDynamicMaterialInstance(ButtonMaterialIndex);
		ButtonMaterialInstance.SetVectorParameterValue(n"Emissive Tint", CurrentShape.Color);
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		InteractComp.Disable(n"InUse");

		FTransform AlignTransform;

		//Reference for broadcasting to level BP for VO Events
		InteractingPlayer = Player;

		if(AnimationHasAlignInfo)
		{
			if(Player.IsCody())
				Animation::GetAnimAlignBoneTransform(AlignTransform, CodyAnim, 0.f);
			else
				Animation::GetAnimAlignBoneTransform(AlignTransform, MayAnim, 0.f);

			float AlignOffset;
			AlignOffset = AlignTransform.Location.X;
			FVector AlignPosition = Player.ActorLocation - Root.WorldLocation;
			AlignPosition = AlignPosition.GetSafeNormal();
			AlignPosition *= AlignOffset;
			AlignPosition += Root.WorldLocation;

			Player.SetActorLocation(AlignPosition);
		}

		Player.CleanupCurrentMovementTrail();

		FVector Direction = Root.WorldLocation - Player.ActorLocation;
		FRotator LookAtRotation = Math::MakeRotFromX(Direction);

		Player.SetActorRotation(FRotator(Player.ActorRotation.Pitch, LookAtRotation.Yaw, Player.ActorRotation.Roll));

		if(Player.IsCody())
		{
			PlayAnimation(Player, CodyAnim);
		}
		else
		{
			PlayAnimation(Player, MayAnim);
		}

		AnimNotifyDelegate.BindUFunction(this, n"OnAnimationNotify");
		Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		LavaLampHazeAkComp.HazePostEvent(PlayInteractAudioEvent);
	}

	UFUNCTION()
	void OnAnimationNotify(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		if(Actor.HasControl())
		{
			GetRandomShape();

			NetSetTargetShape(TargetIndex);
			NetPlayTimeLine();
		}

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

		if(Player != nullptr && OnInteractForceFeedback != nullptr)
		{
			Player.PlayForceFeedback(OnInteractForceFeedback, false, false, n"LavaLampInteract");
		}
	}

	UFUNCTION()
	void PlayAnimation(AHazePlayerCharacter Player, UAnimSequence AnimationToPlay)
	{
		Player.PlayEventAnimation(Animation = AnimationToPlay);
	}

	UFUNCTION()
	void OnTimeLikeUpdate(float Value)
	{
		FLinearColor NewColor = FMath::Lerp(CurrentShape.Color, TargetShape.Color, Value);
		float NewBlobOffset = FMath::Lerp(CurrentShape.BlobOffset, TargetShape.BlobOffset, Value);
		float NewBlobSize = FMath::Lerp(CurrentShape.BlobSize, TargetShape.BlobSize, Value);
		float NewBlobBlending = FMath::Lerp(CurrentShape.BlobBlending, TargetShape.BlobBlending, Value);
		float NewBoxness = FMath::Lerp(CurrentShape.Boxness, TargetShape.Boxness, Value);

		SetLinearColorParam(n"Color", NewColor);
		SetScalarParam(n"BlobOffset", NewBlobOffset);
		SetScalarParam(n"BlobSize", NewBlobSize);
		SetScalarParam(n"BlobBlending", NewBlobBlending);
		SetScalarParam(n"Boxness", NewBoxness);

		if(bUsePointLight)
		{
			PointLightComp.SetLightColor(NewColor);
		}

		if(HazeSphere != nullptr)
		{
			UHazeSphereComponent HazeComp = HazeSphere.HazeSphereComponent;
			HazeComp.SetColor(HazeComp.Opacity, HazeComp.Softness, FLinearColor(NewColor.R, NewColor.G, NewColor.B, HazeComp.ColorA.A));
		}
	}

	UFUNCTION()
	void OnTimeLikeFinished()
	{
		ShapeIndex = TargetIndex;
		CurrentShape = ShapePresets[ShapeIndex];

		if(InteractingPlayer != nullptr)
		{
			if(InteractingPlayer.IsMay() && CurrentShape.ColorState == ELavaLampColor::Blue)
				OnTriggerLavaLampVOEvent.Broadcast(true);
			else if(InteractingPlayer.IsCody() && CurrentShape.ColorState == ELavaLampColor::Green)
				OnTriggerLavaLampVOEvent.Broadcast(false);
		}

		InteractingPlayer = nullptr;
		InteractComp.Enable(n"InUse");
	}

//	Shader / Shape related functions

	void SetScalarParam(FName ParamName, float Value)
	{
		LampMesh.SetScalarParameterValueOnMaterialIndex(LavaMaterialIndex, ParamName, Value);
	}

	void SetLinearColorParam(FName ParamName, FLinearColor Color)
	{
		LampMesh.SetColorParameterValueOnMaterialIndex(LavaMaterialIndex, ParamName, Color);
	}

	void SaveDefaultShape()
	{
		DynMaterial = LampMesh.CreateDynamicMaterialInstance(LavaMaterialIndex);

		FLavaLampSettings DefaultSettings;
		DefaultSettings.Color = DynMaterial.GetVectorParameterValue(n"Color");
		DefaultSettings.BlobOffset = DynMaterial.GetScalarParameterValue(n"BlobOffset");
		DefaultSettings.BlobSize = DynMaterial.GetScalarParameterValue(n"BlobSize");
		DefaultSettings.BlobBlending = DynMaterial.GetScalarParameterValue(n"BlobBlending");
		DefaultSettings.Boxness = DynMaterial.GetScalarParameterValue(n"Boxness");
		DefaultSettings.ColorState = ELavaLampColor::Custom;

		ShapePresets.Add(DefaultSettings);
		CurrentShape = ShapePresets.Last();
		ShapeIndex = ShapePresets.Num() - 1;
	}

	void GetRandomShape()
	{
		TargetIndex = FMath::RandRange(1, ShapePresets.Num());
		TargetIndex--;

		while(TargetIndex == ShapeIndex)
		{
			TargetIndex = FMath::RandRange(1, ShapePresets.Num());
			TargetIndex--;
		}
	}

	void SetShape(int Index)
	{
		FLavaLampSettings ShapeToUse = ShapePresets[Index];

		SetLinearColorParam(n"Color", ShapeToUse.Color);
		SetScalarParam(n"BlobOffset", ShapeToUse.BlobOffset);
		SetScalarParam(n"BlobSize", ShapeToUse.BlobSize);
		SetScalarParam(n"BlobBlending", ShapeToUse.BlobBlending);
		SetScalarParam(n"Boxness", ShapeToUse.Boxness);
	}

	int GetShapeIndexFromState(ELavaLampColor ColorState)
	{
		for(int i = 0; i < ShapePresets.Num(); i++)
		{
			if(ShapePresets[i].ColorState == ColorState)
			{
				return i;
			}
		}

		return 0;
	}

	// Used for linked Remote Control Actor
	int GetRandomShapeForRemote()
	{
		TargetIndex = FMath::RandRange(1, ShapePresets.Num());
		TargetIndex--;

		while(TargetIndex == ShapeIndex)
		{
			TargetIndex = FMath::RandRange(1, ShapePresets.Num());
			TargetIndex--;
		}

		return TargetIndex;
	}

//	NetFunctions

	UFUNCTION(NetFunction)
	void SetNewShape(int TargetShape)
	{
		NetSetTargetShape(TargetShape);
		NetPlayTimeLine();
	}

	UFUNCTION(NetFunction)
	void NetSetTargetShape(int NewIndex)
	{
		TargetShape = ShapePresets[NewIndex];
		TargetIndex = NewIndex;

		ButtonMaterialInstance.SetVectorParameterValue(n"Emissive Tint", TargetShape.Color);
	}

	UFUNCTION(NetFunction)
	void NetPlayTimeLine()
	{
		BlendTimeLike.PlayFromStart();
	}



}

UCLASS(meta = ("Spawn Decal Attached"))
class UAnimNotify_SpawnDecalAttached : UAnimNotify 
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	FName BoneName = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	UMaterialInterface DecalMaterial;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	FVector DecalSize = FVector(1024.f, 1024.f, 1024.f);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	EAttachLocation LocationType = EAttachLocation::KeepRelativeOffset;
//	FAttachmentTransformRules LocationType;

	/* Location - Depending on the value of Location Type this is either a relative offset from the attach component/point or an absolute world position that will be translated to a relative offset */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	FVector Location = FVector::ZeroVector;

	 /* Rotation - Depending on the value of LocationType this is either a relative offset from the attach component/point or an absolute world rotation that will be translated to a relative offset */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	FRotator Rotation = FRotator(-90.f, 0.f, 90.f);

	/**
	* Time in seconds to wait before beginning to fade out the decal. Set fade duration and start delay to 0 to make persistent.
	*/
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	float FadeInDuration = 0.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	float FadeInStartDelay = 0.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	float FadeOutStartDelay = 0.f;

	/**
	* Time in seconds for the decal to fade out. Set fade duration and start delay to 0 to make persistent. Only fades in active simulation or game.
	*/
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Decal")
	float FadeOutDuration = 1.f;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
 		return "Spawn Decal Attached " + "(" + BoneName.ToString() + ")";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const 
	{
		if (MeshComp == nullptr)
			return false;

		if (DecalMaterial == nullptr)
			return false;

		UDecalComponent Decal = Gameplay::SpawnDecalAttached(
			DecalMaterial,
			DecalSize,
			MeshComp,
			BoneName,
			Location,
			Rotation,
			LocationType,
			FadeOutDuration + FadeOutStartDelay
		);

		if(FadeInStartDelay != 0.f || FadeInDuration != 0.f)
			Decal.SetFadeIn(FadeInStartDelay, FadeInDuration);

		if(FadeOutStartDelay != 0.f || FadeOutDuration != 0.f)
			Decal.SetFadeOut(FadeOutStartDelay, FadeOutDuration, false);

		return true;
	}

};

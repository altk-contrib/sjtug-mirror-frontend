import {Box, Container, Grid, GridCol, Group} from "@mantine/core";
import classes from "@/app/global.module.css";
import {ReactNode} from "react";
import {articlesFromHelps, getHelp} from "@/serverRpcs";
import type {Article} from "@/serverRpcs";
import {DocNav} from "@/parts/docNav";
import {DocSearch} from "@/parts/docSearch";

export default async function DocsLayout({
                                           children,
                                         }: Readonly<{
  children: ReactNode;
}>) {
  let articles: Article[] = [];
  try {
    const helps = await getHelp();
    articles = articlesFromHelps(helps);
  } catch (error) {
    console.error("Failed to fetch help feed for docs layout", error);
  }
  return (
    <Container className={classes.container}>
      <Grid>
        <GridCol span={2} visibleFrom={"md"}>
          <Box style={{position: "sticky", top: 20}} mt={20}>
            <DocNav articles={articles}/>
          </Box>
        </GridCol>
        <GridCol span={1} visibleFrom={"xs"} hiddenFrom={"md"}/>
        <GridCol span={{base: 12, xs: 10}}>
          <Group hiddenFrom={"md"} style={{position: "sticky", top: 40}} mb={-40}>
            <Box ml={"auto"} mr={"xl"}>
              <DocSearch articles={articles} variant={"mini"}/>
            </Box>
          </Group>
          {children}
        </GridCol>
        <GridCol span={1} visibleFrom={"xs"} hiddenFrom={"md"}/>
      </Grid>
    </Container>
  )
}
